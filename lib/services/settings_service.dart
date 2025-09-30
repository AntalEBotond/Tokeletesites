import 'dart:async'; // ===== 2025 UPGRADE: ütemezés, debounce
import 'dart:convert'; // ===== 2025 UPGRADE: export/import
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// ===== 2025 UPGRADE: új beállítási politika az egyszerű ThemeMode fölé
enum ThemePreference { system, light, dark, scheduled }

class SettingsController extends ChangeNotifier {
  SettingsController._();
  static final SettingsController instance = SettingsController._();

  // ---- Alap beállítások (visszafelé kompatibilis) ----
  ThemePreference _themePref = ThemePreference.system; // 'system' | 'light' | 'dark' | 'scheduled'
  ThemeMode _manualThemeMode = ThemeMode.system; // ha _themePref != scheduled, ez számít
  Locale? _locale; // null => rendszer

  // ---- 2025 extra beállítások ----
  // Dinamikus/seed színezés
  bool _useDynamicColor = true; // Android 12+ Material You színek
  int? _seedArgb; // saját seed-szín (null => alap/dinamikus)
  // Különleges megjelenítés
  bool _trueBlack = false; // AMOLED fekete
  bool _highContrast = false; // nagy kontraszt
  double _textScale = 1.0; // 0.85..1.30
  bool _reduceMotion = false; // animációk csökkentése
  bool _haptics = true; // haptikus visszajelzés engedélyezése

  // Ütemezett téma (pl. 20:00 – 06:00 sötét)
  int _schedStartMin = 20 * 60; // percben 0..1439
  int _schedEndMin = 6 * 60;
  Timer? _scheduleTicker;

  // Debounce-olt profil szinkron
  Timer? _syncDebounce;
  Map<String, dynamic> _pendingPayload = {};

  // ---------------- GETTEREK ----------------
  ThemePreference get themePreference => _themePref;
  ThemeMode get themeMode => _manualThemeMode; // manuális (vagy system) beállítás
  Locale? get locale => _locale;

  /// ===== 2025 UPGRADE:
  /// A MaterialApp-hoz ***EZT*** add át: controller.effectiveThemeMode
  ThemeMode get effectiveThemeMode {
    if (_themePref != ThemePreference.scheduled) {
      return _manualThemeMode;
    }
    return _isDarkNow() ? ThemeMode.dark : ThemeMode.light;
  }

  bool get useDynamicColor => _useDynamicColor;
  Color? get seedColor => _seedArgb == null ? null : Color(_seedArgb!);
  bool get trueBlack => _trueBlack;
  bool get highContrast => _highContrast;
  double get textScale => _textScale;
  bool get reduceMotion => _reduceMotion;
  bool get haptics => _haptics;

  TimeOfDay get scheduledStart =>
      TimeOfDay(hour: _schedStartMin ~/ 60, minute: _schedStartMin % 60);
  TimeOfDay get scheduledEnd =>
      TimeOfDay(hour: _schedEndMin ~/ 60, minute: _schedEndMin % 60);

  // ---------------- INIT / LOAD ----------------
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();

    _loadFromPrefs(sp);
    await _hydrateFromRemote(sp);
    _restartScheduleTickerIfNeeded();

    notifyListeners();
  }

  void _loadFromPrefs(SharedPreferences sp) {
    final tm = sp.getString('profile_theme_mode') ?? 'system';
    _manualThemeMode = _parseThemeMode(tm);

    _themePref = _parseThemePreference(
      sp.getString('profile_theme_pref') ?? _themePrefToString(_themePref),
    );

    final langTag = sp.getString('profile_language_tag');
    if (langTag != null && langTag.isNotEmpty) {
      _locale = _parseLocaleTag(langTag);
    } else {
      final lang = sp.getString('profile_language');
      _locale = (lang != null && lang.isNotEmpty) ? Locale(lang) : null;
    }

    _useDynamicColor = sp.getBool('ui_use_dynamic_color') ?? _useDynamicColor;
    _seedArgb = sp.getInt('ui_seed_color_argb');
    _trueBlack = sp.getBool('ui_true_black') ?? _trueBlack;
    _highContrast = sp.getBool('ui_high_contrast') ?? _highContrast;
    _textScale = (sp.getDouble('ui_text_scale') ?? _textScale).clamp(0.85, 1.30);
    _reduceMotion = sp.getBool('ui_reduce_motion') ?? _reduceMotion;
    _haptics = sp.getBool('ui_haptics') ?? _haptics;

    _schedStartMin = sp.getInt('theme_sched_start_min') ?? _schedStartMin;
    _schedEndMin = sp.getInt('theme_sched_end_min') ?? _schedEndMin;
  }

  Future<bool> _hydrateFromRemote(SharedPreferences sp) async {
    final token = sp.getString('auth_token');
    if (token == null || token.isEmpty) {
      return false;
    }
    try {
      final remote = await ApiService().getProfile(token);
      final changed = await _applyRemoteSettings(remote, sp);
      return changed;
    } catch (_) {
      return false;
    }
  }

  // ---------------- SETTEREK + MENTÉS + SYNC ----------------

  /// Gyors váltó: system → dark → light → system...
  void quickToggleTheme() {
    switch (_themePref) {
      case ThemePreference.system:
        setThemePreference(ThemePreference.dark);
        break;
      case ThemePreference.dark:
        setThemePreference(ThemePreference.light);
        break;
      case ThemePreference.light:
      case ThemePreference.scheduled:
        setThemePreference(ThemePreference.system);
        break;
    }
  }

  Future<void> setThemePreference(ThemePreference pref) async {
    if (_themePref == pref) return;
    _themePref = pref;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('profile_theme_pref', _themePrefToString(pref));
    _restartScheduleTickerIfNeeded();
    _debouncedSync({'theme_pref': _themePrefToString(pref)});
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    // Manuális ThemeMode (ha nem ütemezett)
    if (_manualThemeMode == mode) return;
    _manualThemeMode = mode;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('profile_theme_mode', _themeToString(mode));
    _debouncedSync({'theme_mode': _themeToString(mode)});
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    final prev = _locale?.toLanguageTag();
    final next = locale?.toLanguageTag();
    if (prev == next) return;
    _locale = locale;
    final sp = await SharedPreferences.getInstance();
    if (next == null || next.isEmpty) {
      await sp.remove('profile_language_tag');
      // régi kulcs tisztítás
      await sp.remove('profile_language');
    } else {
      await sp.setString('profile_language_tag', next);
      await sp.setString('profile_language', locale!.languageCode);
    }
    _debouncedSync({'language_tag': next});
    notifyListeners();
  }

  Future<void> setUseDynamicColor(bool v) async {
    if (_useDynamicColor == v) return;
    _useDynamicColor = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('ui_use_dynamic_color', v);
    _debouncedSync({'use_dynamic_color': v});
    notifyListeners();
  }

  Future<void> setSeedColor(Color? color) async {
    final argb = color?.value;
    if (_seedArgb == argb) return;
    _seedArgb = argb;
    final sp = await SharedPreferences.getInstance();
    if (argb == null) {
      await sp.remove('ui_seed_color_argb');
    } else {
      await sp.setInt('ui_seed_color_argb', argb);
    }
    _debouncedSync({'seed_color_argb': argb});
    notifyListeners();
  }

  Future<void> setTrueBlack(bool v) async {
    if (_trueBlack == v) return;
    _trueBlack = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('ui_true_black', v);
    _debouncedSync({'true_black': v});
    notifyListeners();
  }

  Future<void> setHighContrast(bool v) async {
    if (_highContrast == v) return;
    _highContrast = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('ui_high_contrast', v);
    _debouncedSync({'high_contrast': v});
    notifyListeners();
  }

  Future<void> setTextScale(double v) async {
    final nv = v.clamp(0.85, 1.30);
    if (_textScale == nv) return;
    _textScale = nv;
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble('ui_text_scale', _textScale);
    _debouncedSync({'text_scale': _textScale});
    notifyListeners();
  }

  Future<void> setReduceMotion(bool v) async {
    if (_reduceMotion == v) return;
    _reduceMotion = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('ui_reduce_motion', v);
    _debouncedSync({'reduce_motion': v});
    notifyListeners();
  }

  Future<void> setHaptics(bool v) async {
    if (_haptics == v) return;
    _haptics = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('ui_haptics', v);
    _debouncedSync({'haptics': v});
    notifyListeners();
  }

  /// Ütemezett sötét mód időablak beállítása (helyi idő szerint)
  Future<void> setThemeSchedule({
    required TimeOfDay start,
    required TimeOfDay end,
  }) async {
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    if (_schedStartMin == s && _schedEndMin == e) return;

    _schedStartMin = s;
    _schedEndMin = e;

    final sp = await SharedPreferences.getInstance();
    await sp.setInt('theme_sched_start_min', _schedStartMin);
    await sp.setInt('theme_sched_end_min', _schedEndMin);

    _debouncedSync({
      'theme_schedule': {'start_min': _schedStartMin, 'end_min': _schedEndMin}
    });

    _restartScheduleTickerIfNeeded();
    notifyListeners();
  }

  // ---------------- EXPORT / IMPORT / RESET ----------------

  /// Exportálja az összes beállítást JSON-ként (UI-ból elmentheted fájlba)
  Future<String> exportSettingsJson() async {
    final map = <String, dynamic>{
      'theme_pref': _themePrefToString(_themePref),
      'theme_mode': _themeToString(_manualThemeMode),
      'language_tag': _locale?.toLanguageTag(),
      'use_dynamic_color': _useDynamicColor,
      'seed_color_argb': _seedArgb,
      'true_black': _trueBlack,
      'high_contrast': _highContrast,
      'text_scale': _textScale,
      'reduce_motion': _reduceMotion,
      'haptics': _haptics,
      'theme_sched_start_min': _schedStartMin,
      'theme_sched_end_min': _schedEndMin,
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Importálás JSON-ből (érvényes kulcsok felülírják a jelenlegi beállításokat)
  Future<void> importSettingsJson(String jsonStr) async {
    final data = jsonDecode(jsonStr);
    if (data is! Map<String, dynamic>) return;

    final sp = await SharedPreferences.getInstance();

    if (data['theme_pref'] is String) {
      _themePref = _parseThemePreference(data['theme_pref']);
      await sp.setString('profile_theme_pref', data['theme_pref']);
    }
    if (data['theme_mode'] is String) {
      _manualThemeMode = _parseThemeMode(data['theme_mode']);
      await sp.setString('profile_theme_mode', data['theme_mode']);
    }
    if (data['language_tag'] is String?) {
      final tag = data['language_tag'] as String?;
      _locale = (tag == null || tag.isEmpty) ? null : _parseLocaleTag(tag);
      if (tag == null || tag.isEmpty) {
        await sp.remove('profile_language_tag');
        await sp.remove('profile_language');
      } else {
        await sp.setString('profile_language_tag', tag);
        await sp.setString('profile_language', _locale!.languageCode);
      }
    }
    if (data['use_dynamic_color'] is bool) {
      _useDynamicColor = data['use_dynamic_color'];
      await sp.setBool('ui_use_dynamic_color', _useDynamicColor);
    }
    if (data['seed_color_argb'] is int?) {
      _seedArgb = data['seed_color_argb'];
      if (_seedArgb == null) {
        await sp.remove('ui_seed_color_argb');
      } else {
        await sp.setInt('ui_seed_color_argb', _seedArgb!);
      }
    }
    if (data['true_black'] is bool) {
      _trueBlack = data['true_black'];
      await sp.setBool('ui_true_black', _trueBlack);
    }
    if (data['high_contrast'] is bool) {
      _highContrast = data['high_contrast'];
      await sp.setBool('ui_high_contrast', _highContrast);
    }
    if (data['text_scale'] is num) {
      _textScale = (data['text_scale'] as num).toDouble().clamp(0.85, 1.30);
      await sp.setDouble('ui_text_scale', _textScale);
    }
    if (data['reduce_motion'] is bool) {
      _reduceMotion = data['reduce_motion'];
      await sp.setBool('ui_reduce_motion', _reduceMotion);
    }
    if (data['haptics'] is bool) {
      _haptics = data['haptics'];
      await sp.setBool('ui_haptics', _haptics);
    }
    if (data['theme_sched_start_min'] is int) {
      _schedStartMin = data['theme_sched_start_min'];
      await sp.setInt('theme_sched_start_min', _schedStartMin);
    }
    if (data['theme_sched_end_min'] is int) {
      _schedEndMin = data['theme_sched_end_min'];
      await sp.setInt('theme_sched_end_min', _schedEndMin);
    }

    _restartScheduleTickerIfNeeded();
    notifyListeners();
  }

  /// Teljes visszaállítás (lokális tároló törlés + memóriában alapértékek)
  Future<void> resetToDefaults() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('profile_theme_pref');
    await sp.remove('profile_theme_mode');
    await sp.remove('profile_language_tag');
    await sp.remove('profile_language');
    await sp.remove('ui_use_dynamic_color');
    await sp.remove('ui_seed_color_argb');
    await sp.remove('ui_true_black');
    await sp.remove('ui_high_contrast');
    await sp.remove('ui_text_scale');
    await sp.remove('ui_reduce_motion');
    await sp.remove('ui_haptics');
    await sp.remove('theme_sched_start_min');
    await sp.remove('theme_sched_end_min');

    _themePref = ThemePreference.system;
    _manualThemeMode = ThemeMode.system;
    _locale = null;
    _useDynamicColor = true;
    _seedArgb = null;
    _trueBlack = false;
    _highContrast = false;
    _textScale = 1.0;
    _reduceMotion = false;
    _haptics = true;
    _schedStartMin = 20 * 60;
    _schedEndMin = 6 * 60;
    _restartScheduleTickerIfNeeded();
    _pendingPayload.clear();

    _debouncedSync({'reset': true});
    notifyListeners();
  }

  // ---------------- BELSŐ LOGIKA ----------------

  void _restartScheduleTickerIfNeeded() {
    _scheduleTicker?.cancel();
    if (_themePref != ThemePreference.scheduled) return;
    // Átállítjuk úgy, hogy a következő határidőben (start vagy end) fusson le
    final now = DateTime.now();
    final msUntil = _millisUntilNextBoundary(now);
    _scheduleTicker = Timer(Duration(milliseconds: msUntil), () {
      // határon átléptünk → új effectiveThemeMode
      notifyListeners();
      // és ütemezzük a következő váltást
      _restartScheduleTickerIfNeeded();
    });
  }

  bool _isDarkNow() {
    final now = DateTime.now();
    final m = now.hour * 60 + now.minute;
    // Kezdés és befejezés átlapolhat éjfélen: pl. 20:00 → 06:00
    if (_schedStartMin <= _schedEndMin) {
      // pl. 08:00 → 18:00 (nappali sötét, ritkább)
      return m >= _schedStartMin && m < _schedEndMin;
    } else {
      // pl. 20:00 → 06:00 (éjszakai sötét, tipikus)
      return m >= _schedStartMin || m < _schedEndMin;
    }
  }

  int _millisUntilNextBoundary(DateTime now) {
    final m = now.hour * 60 + now.minute;
    int nextMin;
    // következő váltás a közelebbi határpont
    final deltas = <int>[
      _deltaForwardMinutes(m, _schedStartMin),
      _deltaForwardMinutes(m, _schedEndMin),
    ];
    nextMin = deltas.reduce((a, b) => a < b ? a : b);
    // a percre igazítunk + másodperc/ezredmásodperc korrekció
    final next = now.add(Duration(minutes: nextMin));
    final aligned = DateTime(
      next.year,
      next.month,
      next.day,
      next.hour,
      next.minute,
    );
    return aligned.difference(now).inMilliseconds.clamp(500, 24 * 60 * 60 * 1000);
  }

  int _deltaForwardMinutes(int fromMin, int toMin) {
    if (toMin >= fromMin) return toMin - fromMin;
    return 1440 - (fromMin - toMin);
  }

  void _debouncedSync(Map<String, dynamic> payload) {
    // ===== 2025 UPGRADE: kíméletes, összevont szinkron
    _pendingPayload.addAll(payload);
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(seconds: 2), () {
      _syncProfile(_pendingPayload);
      _pendingPayload = {};
    });
  }

  Future<void> _syncProfile(Map<String, dynamic> payload) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('auth_token');
      if (token == null || token.isEmpty) return;
      final updated = await ApiService().updateProfile(token, payload);
      final mutated = await _applyRemoteSettings(updated, sp);
      if (mutated) {
        _restartScheduleTickerIfNeeded();
        notifyListeners();
      }
    } catch (_) {
      // Best-effort; offline stb. → majd legközelebb
    }
  }

  // ---------------- SEGÉDFÜGGVÉNYEK ----------------

  Future<bool> _applyRemoteSettings(
    Map<String, dynamic> remote,
    SharedPreferences sp,
  ) async {
    bool mutated = false;

    final themePrefRaw = _stringValue(remote['theme_pref']);
    if (themePrefRaw != null) {
      final pref = _parseThemePreference(themePrefRaw);
      if (_themePref != pref) {
        _themePref = pref;
        await sp.setString('profile_theme_pref', themePrefRaw);
        mutated = true;
      }
    }

    final themeModeRaw = _stringValue(remote['theme_mode']);
    if (themeModeRaw != null) {
      final mode = _parseThemeMode(themeModeRaw);
      if (_manualThemeMode != mode) {
        _manualThemeMode = mode;
        await sp.setString('profile_theme_mode', themeModeRaw);
        mutated = true;
      }
    }

    final languageTag = _stringValue(remote['language_tag'] ?? remote['language']);
    if (languageTag != null) {
      final locale = _parseLocaleTag(languageTag);
      if (_locale?.toLanguageTag() != locale.toLanguageTag()) {
        _locale = locale;
        await sp.setString('profile_language_tag', languageTag);
        await sp.setString('profile_language', locale.languageCode);
        mutated = true;
      }
    }

    final dynamicColorRaw = _asBool(remote['use_dynamic_color']);
    if (dynamicColorRaw != null && dynamicColorRaw != _useDynamicColor) {
      _useDynamicColor = dynamicColorRaw;
      await sp.setBool('ui_use_dynamic_color', dynamicColorRaw);
      mutated = true;
    }

    final seedArgbRaw = remote['seed_color_argb'];
    if (seedArgbRaw != null) {
      final argb = _asInt(seedArgbRaw);
      if (argb != null && argb != _seedArgb) {
        _seedArgb = argb;
        await sp.setInt('ui_seed_color_argb', argb);
        mutated = true;
      }
    } else {
      final accentHex = _stringValue(remote['accent_color']);
      final accent = _colorFromHex(accentHex);
      if (accent != null && accent.value != _seedArgb) {
        _seedArgb = accent.value;
        await sp.setInt('ui_seed_color_argb', accent.value);
        mutated = true;
      }
    }

    final trueBlackRaw = _asBool(remote['true_black']);
    if (trueBlackRaw != null && trueBlackRaw != _trueBlack) {
      _trueBlack = trueBlackRaw;
      await sp.setBool('ui_true_black', trueBlackRaw);
      mutated = true;
    }

    final highContrastRaw = _asBool(remote['high_contrast']);
    if (highContrastRaw != null && highContrastRaw != _highContrast) {
      _highContrast = highContrastRaw;
      await sp.setBool('ui_high_contrast', highContrastRaw);
      mutated = true;
    }

    final reduceMotionRaw = _asBool(remote['reduce_motion']);
    if (reduceMotionRaw != null && reduceMotionRaw != _reduceMotion) {
      _reduceMotion = reduceMotionRaw;
      await sp.setBool('ui_reduce_motion', reduceMotionRaw);
      mutated = true;
    }

    final hapticsRaw = _asBool(remote['haptics']);
    if (hapticsRaw != null && hapticsRaw != _haptics) {
      _haptics = hapticsRaw;
      await sp.setBool('ui_haptics', hapticsRaw);
      mutated = true;
    }

    final textScaleRaw = remote['text_scale'];
    final parsedTextScale = _asDouble(textScaleRaw);
    if (parsedTextScale != null && parsedTextScale != _textScale) {
      _textScale = parsedTextScale.clamp(0.85, 1.30);
      await sp.setDouble('ui_text_scale', _textScale);
      mutated = true;
    }

    int? startMin;
    int? endMin;
    final schedule = remote['theme_schedule'];
    if (schedule is Map) {
      startMin = _asInt(schedule['start_min']);
      endMin = _asInt(schedule['end_min']);
    }
    startMin ??= _asInt(remote['theme_sched_start_min']);
    endMin ??= _asInt(remote['theme_sched_end_min']);
    if (startMin != null && endMin != null) {
      final normalizedStart = startMin.clamp(0, 1439);
      final normalizedEnd = endMin.clamp(0, 1439);
      if (_schedStartMin != normalizedStart || _schedEndMin != normalizedEnd) {
        _schedStartMin = normalizedStart;
        _schedEndMin = normalizedEnd;
        await sp.setInt('theme_sched_start_min', _schedStartMin);
        await sp.setInt('theme_sched_end_min', _schedEndMin);
        mutated = true;
      }
    }

    return mutated;
  }

  String? _stringValue(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) return null;
      if (['true', '1', 'yes', 'y', 'on'].contains(normalized)) return true;
      if (['false', '0', 'no', 'n', 'off'].contains(normalized)) return false;
    }
    return null;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Color? _colorFromHex(String? hex) {
    if (hex == null) return null;
    final sanitized = hex.replaceAll('#', '');
    if (sanitized.length == 6) {
      return Color(int.parse('FF$sanitized', radix: 16));
    }
    if (sanitized.length == 8) {
      return Color(int.parse(sanitized, radix: 16));
    }
    return null;
  }

  ThemeMode _parseThemeMode(String v) {
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  ThemePreference _parseThemePreference(String v) {
    switch (v) {
      case 'light':
        return ThemePreference.light;
      case 'dark':
        return ThemePreference.dark;
      case 'scheduled':
        return ThemePreference.scheduled;
      case 'system':
      default:
        return ThemePreference.system;
    }
  }

  String _themePrefToString(ThemePreference p) {
    switch (p) {
      case ThemePreference.light:
        return 'light';
      case ThemePreference.dark:
        return 'dark';
      case ThemePreference.scheduled:
        return 'scheduled';
      case ThemePreference.system:
      default:
        return 'system';
    }
  }

  Locale _parseLocaleTag(String tag) {
    // Egyszerű parser: "ro", "ro-RO", "en-US" stb.
    final parts = tag.split(RegExp('[-_]'));
    if (parts.length == 1) return Locale(parts[0]);
    if (parts.length == 2) return Locale(parts[0], parts[1]);
    // ha script is lenne (pl. zh-Hant-TW), a 3. elemet ignoráljuk itt
    return Locale(parts[0], parts[1]);
  }
}
