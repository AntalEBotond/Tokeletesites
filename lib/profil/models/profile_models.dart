import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

String? _cleanString(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Color colorFromHex(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) {
    return fallback;
  }
  final sanitized = hex.replaceAll('#', '');
  try {
    if (sanitized.length == 6) {
      return Color(int.parse('FF$sanitized', radix: 16));
    }
    if (sanitized.length == 8) {
      return Color(int.parse(sanitized, radix: 16));
    }
  } catch (_) {}
  return fallback;
}

String colorToHex(Color color) {
  final value = color.value.toRadixString(16).padLeft(8, '0');
  return '#${value.substring(2)}';
}

Uint8List? _decodeBase64(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  try {
    return base64Decode(value);
  } catch (_) {
    return null;
  }
}

String? _encodeBase64(Uint8List? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return base64Encode(value);
}

class SocialLinks {
  const SocialLinks({
    this.facebook,
    this.instagram,
    this.tiktok,
    this.youtube,
  });

  final String? facebook;
  final String? instagram;
  final String? tiktok;
  final String? youtube;

  bool get hasAny =>
      [facebook, instagram, tiktok, youtube].any((value) => value != null && value.isNotEmpty);

  SocialLinks copyWith({
    String? facebook,
    String? instagram,
    String? tiktok,
    String? youtube,
  }) {
    return SocialLinks(
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      tiktok: tiktok ?? this.tiktok,
      youtube: youtube ?? this.youtube,
    );
  }

  Map<String, dynamic> toPrefs() => <String, dynamic>{
        'profile_facebook': facebook,
        'profile_instagram': instagram,
        'profile_tiktok': tiktok,
        'profile_youtube': youtube,
      };

  static SocialLinks fromPrefs(SharedPreferences prefs) {
    return SocialLinks(
      facebook: _cleanString(prefs.getString('profile_facebook')),
      instagram: _cleanString(prefs.getString('profile_instagram')),
      tiktok: _cleanString(prefs.getString('profile_tiktok')),
      youtube: _cleanString(prefs.getString('profile_youtube')),
    );
  }
}

class AvatarDetails {
  const AvatarDetails({
    this.url,
    this.localPath,
    this.bytes,
  });

  final String? url;
  final String? localPath;
  final Uint8List? bytes;

  bool get hasImage =>
      (url != null && url!.isNotEmpty) ||
      (localPath != null && localPath!.isNotEmpty) ||
      (bytes != null && bytes!.isNotEmpty);

  AvatarDetails copyWith({
    String? url,
    String? localPath,
    Uint8List? bytes,
  }) {
    return AvatarDetails(
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      bytes: bytes ?? this.bytes,
    );
  }

  Map<String, dynamic> toPrefs() => <String, dynamic>{
        'profile_avatar_url': url,
        'profile_avatar': localPath,
        'profile_avatar_b64': _encodeBase64(bytes),
      };

  static AvatarDetails fromPrefs(SharedPreferences prefs) {
    return AvatarDetails(
      url: _cleanString(prefs.getString('profile_avatar_url')),
      localPath: kIsWeb ? null : _cleanString(prefs.getString('profile_avatar')),
      bytes: kIsWeb ? _decodeBase64(prefs.getString('profile_avatar_b64')) : null,
    );
  }
}

class BannerDetails {
  const BannerDetails({
    this.url,
    this.localPath,
    this.bytes,
  });

  final String? url;
  final String? localPath;
  final Uint8List? bytes;

  bool get hasImage =>
      (url != null && url!.isNotEmpty) ||
      (localPath != null && localPath!.isNotEmpty) ||
      (bytes != null && bytes!.isNotEmpty);

  BannerDetails copyWith({
    String? url,
    String? localPath,
    Uint8List? bytes,
  }) {
    return BannerDetails(
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      bytes: bytes ?? this.bytes,
    );
  }

  Map<String, dynamic> toPrefs() => <String, dynamic>{
        'profile_banner_url': url,
        'profile_banner': localPath,
        'profile_banner_b64': _encodeBase64(bytes),
      };

  static BannerDetails fromPrefs(SharedPreferences prefs) {
    return BannerDetails(
      url: _cleanString(prefs.getString('profile_banner_url')),
      localPath: kIsWeb ? null : _cleanString(prefs.getString('profile_banner')),
      bytes: kIsWeb ? _decodeBase64(prefs.getString('profile_banner_b64')) : null,
    );
  }
}

class StatusNote {
  const StatusNote({
    this.text,
    this.expiresAt,
    this.emoji,
    this.textColor = Colors.white,
    this.backgroundColor = const Color(0xDD000000),
  });

  final String? text;
  final DateTime? expiresAt;
  final String? emoji;
  final Color textColor;
  final Color backgroundColor;

  bool get isActive {
    if (text == null || text!.isEmpty) {
      return false;
    }
    if (expiresAt == null) {
      return true;
    }
    return expiresAt!.isAfter(DateTime.now());
  }

  StatusNote copyWith({
    String? text,
    DateTime? expiresAt,
    String? emoji,
    Color? textColor,
    Color? backgroundColor,
  }) {
    return StatusNote(
      text: text ?? this.text,
      expiresAt: expiresAt ?? this.expiresAt,
      emoji: emoji ?? this.emoji,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  Map<String, dynamic> toPrefs() => <String, dynamic>{
        'profile_status_note': text,
        'profile_status_note_expires': expiresAt?.toIso8601String(),
        'profile_status_note_color': colorToHex(textColor),
        'profile_status_note_bg': colorToHex(backgroundColor),
        'profile_status_note_emoji': emoji,
      };

  static StatusNote fromPrefs(SharedPreferences prefs) {
    final expiresRaw = prefs.getString('profile_status_note_expires');
    DateTime? expires;
    if (expiresRaw != null && expiresRaw.isNotEmpty) {
      expires = DateTime.tryParse(expiresRaw);
    }
    return StatusNote(
      text: _cleanString(prefs.getString('profile_status_note')),
      expiresAt: expires,
      emoji: _cleanString(prefs.getString('profile_status_note_emoji')),
      textColor: colorFromHex(prefs.getString('profile_status_note_color'), Colors.white),
      backgroundColor: colorFromHex(prefs.getString('profile_status_note_bg'), const Color(0xDD000000)),
    );
  }
}

class PersonalPreferences {
  const PersonalPreferences({
    this.reduceMotion = false,
    this.haloStrength = 0.65,
    this.themeMode = 'system',
    this.accentColor = const Color(0xFF00C853),
    this.compactMode = false,
    this.textScale = 1.0,
    this.language,
    this.frameFavorites = const <String>{},
  });

  final bool reduceMotion;
  final double haloStrength;
  final String themeMode;
  final Color accentColor;
  final bool compactMode;
  final double textScale;
  final String? language;
  final Set<String> frameFavorites;

  PersonalPreferences copyWith({
    bool? reduceMotion,
    double? haloStrength,
    String? themeMode,
    Color? accentColor,
    bool? compactMode,
    double? textScale,
    String? language,
    Set<String>? frameFavorites,
  }) {
    return PersonalPreferences(
      reduceMotion: reduceMotion ?? this.reduceMotion,
      haloStrength: haloStrength ?? this.haloStrength,
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      compactMode: compactMode ?? this.compactMode,
      textScale: textScale ?? this.textScale,
      language: language ?? this.language,
      frameFavorites: frameFavorites ?? this.frameFavorites,
    );
  }

  Map<String, dynamic> toPrefs() => <String, dynamic>{
        'profile_reduce_motion': reduceMotion,
        'profile_halo_strength': haloStrength,
        'profile_theme_mode': themeMode,
        'profile_accent_color': colorToHex(accentColor),
        'profile_compact_mode': compactMode,
        'profile_text_scale': textScale,
        'profile_language': language,
        'profile_frame_favs': frameFavorites.toList(),
      };

  static PersonalPreferences fromPrefs(SharedPreferences prefs) {
    final halo = (prefs.getDouble('profile_halo_strength') ?? 0.65).clamp(0.0, 1.0);
    final textScale = (prefs.getDouble('profile_text_scale') ?? 1.0).clamp(0.9, 1.2);
    return PersonalPreferences(
      reduceMotion: prefs.getBool('profile_reduce_motion') ?? false,
      haloStrength: halo,
      themeMode: prefs.getString('profile_theme_mode') ?? 'system',
      accentColor: colorFromHex(prefs.getString('profile_accent_color'), const Color(0xFF00C853)),
      compactMode: prefs.getBool('profile_compact_mode') ?? false,
      textScale: textScale,
      language: _cleanString(prefs.getString('profile_language')),
      frameFavorites: (prefs.getStringList('profile_frame_favs') ?? const <String>[]).toSet(),
    );
  }
}

class ProfileData {
  ProfileData({
    required this.name,
    required this.description,
    required this.social,
    required this.avatar,
    required this.banner,
    required this.status,
    required this.avatarFrame,
    required this.preferences,
    this.avatarSticker,
    this.pronouns,
    this.websiteUrl,
    this.location,
    this.authToken,
  });

  factory ProfileData.initial() => ProfileData(
        name: '',
        description: '',
        social: const SocialLinks(),
        avatar: const AvatarDetails(),
        banner: const BannerDetails(),
        status: const StatusNote(),
        avatarFrame: 'none',
        preferences: const PersonalPreferences(),
      );

  final String name;
  final String description;
  final SocialLinks social;
  final AvatarDetails avatar;
  final BannerDetails banner;
  final StatusNote status;
  final String avatarFrame;
  final PersonalPreferences preferences;
  final String? avatarSticker;
  final String? pronouns;
  final String? websiteUrl;
  final String? location;
  final String? authToken;

  bool get isAuthenticated => authToken != null && authToken!.isNotEmpty;

  double get completeness {
    var completed = 0;
    if (name.trim().isNotEmpty) completed++;
    if (description.trim().isNotEmpty) completed++;
    if (avatar.hasImage) completed++;
    if (social.hasAny) completed++;
    return completed / 4;
  }

  ProfileData copyWith({
    String? name,
    String? description,
    SocialLinks? social,
    AvatarDetails? avatar,
    BannerDetails? banner,
    StatusNote? status,
    String? avatarFrame,
    PersonalPreferences? preferences,
    String? avatarSticker,
    String? pronouns,
    String? websiteUrl,
    String? location,
    String? authToken,
  }) {
    return ProfileData(
      name: name ?? this.name,
      description: description ?? this.description,
      social: social ?? this.social,
      avatar: avatar ?? this.avatar,
      banner: banner ?? this.banner,
      status: status ?? this.status,
      avatarFrame: avatarFrame ?? this.avatarFrame,
      preferences: preferences ?? this.preferences,
      avatarSticker: avatarSticker ?? this.avatarSticker,
      pronouns: pronouns ?? this.pronouns,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      location: location ?? this.location,
      authToken: authToken ?? this.authToken,
    );
  }

  ProfileData mergeRemote(Map<String, dynamic> remote) {
    StatusNote newStatus = status;
    final remoteText = remote['status_note'] as String?;
    final remoteExpires = remote['status_note_expires'] as String?;
    DateTime? expires;
    if (remoteExpires != null && remoteExpires.isNotEmpty) {
      final parsed = DateTime.tryParse(remoteExpires);
      if (parsed != null && parsed.isAfter(DateTime.now())) {
        expires = parsed;
      }
    }
    newStatus = newStatus.copyWith(
      text: _cleanString(remoteText) ?? newStatus.text,
      expiresAt: expires ?? newStatus.expiresAt,
      textColor: colorFromHex(remote['status_note_color'] as String?, newStatus.textColor),
      backgroundColor: colorFromHex(remote['status_note_bg'] as String?, newStatus.backgroundColor),
      emoji: _cleanString(remote['status_note_emoji'] as String?) ?? newStatus.emoji,
    );

    PersonalPreferences prefs = preferences.copyWith(
      themeMode: remote['theme_mode'] as String? ?? preferences.themeMode,
      accentColor: colorFromHex(remote['accent_color'] as String?, preferences.accentColor),
      compactMode: (remote['compact_mode'] ?? preferences.compactMode) == true,
    );

    final textScaleRaw = remote['text_scale'];
    if (textScaleRaw != null) {
      final parsed = double.tryParse(textScaleRaw.toString());
      if (parsed != null) {
        prefs = prefs.copyWith(textScale: parsed.clamp(0.9, 1.2));
      }
    }

    final haloRaw = remote['halo_strength'];
    if (haloRaw != null) {
      final parsed = double.tryParse(haloRaw.toString());
      if (parsed != null) {
        prefs = prefs.copyWith(haloStrength: parsed.clamp(0, 1));
      }
    }

    final reduceMotion = remote['reduce_motion'];
    if (reduceMotion != null) {
      prefs = prefs.copyWith(reduceMotion: reduceMotion == true);
    }

    final favsRaw = remote['avatar_frame_favs'];
    if (favsRaw != null) {
      try {
        if (favsRaw is String) {
          final decoded = List<String>.from(jsonDecode(favsRaw) as List<dynamic>);
          prefs = prefs.copyWith(frameFavorites: decoded.toSet());
        } else if (favsRaw is List) {
          prefs = prefs.copyWith(frameFavorites: List<String>.from(favsRaw).toSet());
        }
      } catch (_) {}
    }

    return copyWith(
      name: _cleanString(remote['full_name'] as String?) ?? name,
      description: _cleanString(remote['description'] as String?) ?? description,
      social: social.copyWith(
        facebook: _cleanString(remote['social_facebook'] as String?) ?? social.facebook,
        instagram: _cleanString(remote['social_instagram'] as String?) ?? social.instagram,
        tiktok: _cleanString(remote['social_tiktok'] as String?) ?? social.tiktok,
        youtube: _cleanString(remote['social_youtube'] as String?) ?? social.youtube,
      ),
      avatar: avatar.copyWith(url: _cleanString(remote['avatar_url'] as String?) ?? avatar.url),
      banner: banner.copyWith(url: _cleanString(remote['banner_url'] as String?) ?? banner.url),
      avatarFrame: _cleanString(remote['avatar_frame'] as String?) ?? avatarFrame,
      avatarSticker: _cleanString(remote['avatar_sticker'] as String?) ?? avatarSticker,
      pronouns: _cleanString(remote['pronouns'] as String?) ?? pronouns,
      websiteUrl: _cleanString(remote['website_url'] as String?) ?? websiteUrl,
      location: _cleanString(remote['location'] as String?) ?? location,
      status: newStatus,
      preferences: prefs,
    );
  }

  Map<String, dynamic> toUpdatePayload() {
    final payload = <String, dynamic>{
      'full_name': name,
      'description': description,
      'social_facebook': social.facebook,
      'social_instagram': social.instagram,
      'social_tiktok': social.tiktok,
      'social_youtube': social.youtube,
      'avatar_frame': avatarFrame,
      'avatar_sticker': avatarSticker,
      'status_note_color': colorToHex(status.textColor),
      'status_note_bg': colorToHex(status.backgroundColor),
      'theme_mode': preferences.themeMode,
      'accent_color': colorToHex(preferences.accentColor),
      'halo_strength': preferences.haloStrength.toStringAsFixed(2),
      'avatar_frame_favs': preferences.frameFavorites.isEmpty
          ? null
          : jsonEncode(preferences.frameFavorites.toList()),
      'pronouns': pronouns,
      'website_url': websiteUrl,
      'location': location,
      'compact_mode': preferences.compactMode,
      'text_scale': preferences.textScale.toStringAsFixed(2),
      'reduce_motion': preferences.reduceMotion,
    };

    if (status.text != null && status.text!.trim().isNotEmpty) {
      payload['status_note'] = status.text;
    }
    if (status.expiresAt != null) {
      payload['status_note_expires'] = status.expiresAt!.toIso8601String();
    }
    if (status.emoji != null && status.emoji!.isNotEmpty) {
      payload['status_note_emoji'] = status.emoji;
    }

    return payload;
  }

  static Future<ProfileData> fromPrefsAsync(SharedPreferences prefs) async {
    return ProfileData(
      name: prefs.getString('profile_name') ?? '',
      description: prefs.getString('profile_description') ?? '',
      social: SocialLinks.fromPrefs(prefs),
      avatar: AvatarDetails.fromPrefs(prefs),
      banner: BannerDetails.fromPrefs(prefs),
      status: StatusNote.fromPrefs(prefs),
      avatarFrame: prefs.getString('profile_avatar_frame') ?? 'none',
      avatarSticker: _cleanString(prefs.getString('profile_avatar_sticker_asset')),
      pronouns: _cleanString(prefs.getString('profile_pronouns')),
      websiteUrl: _cleanString(prefs.getString('profile_website')),
      location: _cleanString(prefs.getString('profile_location')),
      preferences: PersonalPreferences.fromPrefs(prefs),
      authToken: _cleanString(prefs.getString('auth_token')),
    );
  }

  Future<void> persistSnapshot(SharedPreferences prefs) async {
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_description', description);

    for (final entry in social.toPrefs().entries) {
      if (entry.value == null || (entry.value is String && (entry.value as String).isEmpty)) {
        await prefs.remove(entry.key);
      } else {
        await prefs.setString(entry.key, entry.value as String);
      }
    }

    for (final entry in avatar.toPrefs().entries) {
      final key = entry.key;
      final value = entry.value;
      if (value == null || (value is String && value.isEmpty)) {
        await prefs.remove(key);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    }

    for (final entry in banner.toPrefs().entries) {
      final key = entry.key;
      final value = entry.value;
      if (value == null || (value is String && value.isEmpty)) {
        await prefs.remove(key);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    }

    for (final entry in status.toPrefs().entries) {
      final key = entry.key;
      final value = entry.value;
      if (value == null || (value is String && value.isEmpty)) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value as String);
      }
    }

    await prefs.setString('profile_avatar_frame', avatarFrame);
    if (avatarSticker == null || avatarSticker!.isEmpty) {
      await prefs.remove('profile_avatar_sticker_asset');
    } else {
      await prefs.setString('profile_avatar_sticker_asset', avatarSticker!);
    }

    if (pronouns == null || pronouns!.isEmpty) {
      await prefs.remove('profile_pronouns');
    } else {
      await prefs.setString('profile_pronouns', pronouns!);
    }

    if (websiteUrl == null || websiteUrl!.isEmpty) {
      await prefs.remove('profile_website');
    } else {
      await prefs.setString('profile_website', websiteUrl!);
    }

    if (location == null || location!.isEmpty) {
      await prefs.remove('profile_location');
    } else {
      await prefs.setString('profile_location', location!);
    }

    await prefs.setBool('profile_reduce_motion', preferences.reduceMotion);
    await prefs.setDouble('profile_halo_strength', preferences.haloStrength);
    await prefs.setString('profile_theme_mode', preferences.themeMode);
    await prefs.setString('profile_accent_color', colorToHex(preferences.accentColor));
    await prefs.setBool('profile_compact_mode', preferences.compactMode);
    await prefs.setDouble('profile_text_scale', preferences.textScale);
    if (preferences.language == null || preferences.language!.isEmpty) {
      await prefs.remove('profile_language');
    } else {
      await prefs.setString('profile_language', preferences.language!);
    }
    await prefs.setStringList('profile_frame_favs', preferences.frameFavorites.toList());
  }
}
