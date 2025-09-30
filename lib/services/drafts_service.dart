import 'package:shared_preferences/shared_preferences.dart';

class DraftsService {
  static const _kText = 'post_draft_text';
  static const _kBg = 'post_draft_bg';
  static const _kFg = 'post_draft_fg';
  static const _kEmoji = 'post_draft_emoji';
  static const _kVisibility = 'post_draft_visibility';

  static Future<void> save({
    String? text,
    String? bg,
    String? fg,
    String? emoji,
    String? visibility,
  }) async {
    final sp = await SharedPreferences.getInstance();
    if (text != null) await sp.setString(_kText, text);
    if (bg != null) await sp.setString(_kBg, bg);
    if (fg != null) await sp.setString(_kFg, fg);
    if (emoji != null) await sp.setString(_kEmoji, emoji);
    if (visibility != null) await sp.setString(_kVisibility, visibility);
  }

  static Future<({String? text, String? bg, String? fg, String? emoji, String? visibility})> load() async {
    final sp = await SharedPreferences.getInstance();
    return (
      text: sp.getString(_kText),
      bg: sp.getString(_kBg),
      fg: sp.getString(_kFg),
      emoji: sp.getString(_kEmoji),
      visibility: sp.getString(_kVisibility),
    );
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kText);
    await sp.remove(_kBg);
    await sp.remove(_kFg);
    await sp.remove(_kEmoji);
    await sp.remove(_kVisibility);
  }
}
