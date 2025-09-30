import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../models/profile_models.dart';

class ProfileAuthException implements Exception {
  const ProfileAuthException();
  @override
  String toString() => 'Missing authentication token';
}

class ProfileRepository {
  ProfileRepository._(this._prefs, this._api);

  final SharedPreferences _prefs;
  final ApiService _api;

  SharedPreferences get prefs => _prefs;

  static Future<ProfileRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ProfileRepository._(prefs, ApiService());
  }

  Future<ProfileData> loadProfile() async {
    final local = await ProfileData.fromPrefsAsync(_prefs);
    final token = local.authToken ?? _prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      return local.copyWith(authToken: null);
    }
    try {
      final remote = await _api.getProfile(token);
      final merged = local.mergeRemote(remote).copyWith(authToken: token);
      await merged.persistSnapshot(_prefs);
      return merged;
    } catch (_) {
      return local.copyWith(authToken: token);
    }
  }

  Future<void> persistDraft(ProfileData data) async {
    await data.persistSnapshot(_prefs);
  }

  Future<void> persistName(String value) async {
    await _prefs.setString('profile_name', value);
  }

  Future<void> persistDescription(String value) async {
    await _prefs.setString('profile_description', value);
  }

  Future<ProfileData> saveProfile(ProfileData data) async {
    final token = data.authToken ?? _prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      throw const ProfileAuthException();
    }
    final updated = await _api.updateProfile(token, {
      ...data.toUpdatePayload(),
      'social_facebook': data.social.facebook,
      'social_instagram': data.social.instagram,
      'social_tiktok': data.social.tiktok,
      'social_youtube': data.social.youtube,
    });
    final merged = data.mergeRemote(updated).copyWith(authToken: token);
    await merged.persistSnapshot(_prefs);
    // keep recently fetched URLs from update payload
    final avatarUrl = _cleanString(updated['avatar_url'] as String?);
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      await _prefs.setString('profile_avatar_url', avatarUrl);
    }
    final bannerUrl = _cleanString(updated['banner_url'] as String?);
    if (bannerUrl != null && bannerUrl.isNotEmpty) {
      await _prefs.setString('profile_banner_url', bannerUrl);
    }
    return merged;
  }

  Future<ProfileData> saveAvatar(ProfileData data, XFile file) async {
    final token = data.authToken ?? _prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      return _saveAvatarOffline(data, file);
    }

    final updated = await _uploadAvatar(token, data, file);
    await updated.persistSnapshot(_prefs);
    return updated;
  }

  Future<ProfileData> _saveAvatarOffline(ProfileData data, XFile file) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await _prefs.setString('profile_avatar_b64', base64Encode(bytes));
      await _prefs.remove('profile_avatar');
      final updated = data.copyWith(
        avatar: data.avatar.copyWith(bytes: bytes, localPath: null),
      );
      await updated.persistSnapshot(_prefs);
      return updated;
    }
    await _prefs.setString('profile_avatar', file.path);
    await _prefs.remove('profile_avatar_b64');
    final updated = data.copyWith(
      avatar: data.avatar.copyWith(localPath: file.path, bytes: null),
    );
    await updated.persistSnapshot(_prefs);
    return updated;
  }

  Future<ProfileData> _uploadAvatar(String token, ProfileData data, XFile file) async {
    String url;
    ProfileData working = data;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await _prefs.setString('profile_avatar_b64', base64Encode(bytes));
      await _prefs.remove('profile_avatar');
      final name = file.name.isNotEmpty ? file.name : 'avatar.jpg';
      url = await _api.uploadAvatarBytes(token, bytes, filename: name);
      working = working.copyWith(avatar: working.avatar.copyWith(bytes: bytes, localPath: null));
    } else {
      await _prefs.setString('profile_avatar', file.path);
      await _prefs.remove('profile_avatar_b64');
      final name = file.name.isNotEmpty ? file.name : 'avatar.jpg';
      url = await _api.uploadAvatarPath(token, file.path, filename: name);
      working = working.copyWith(avatar: working.avatar.copyWith(localPath: file.path, bytes: null));
    }
    final cacheBusted = '$url?v=${DateTime.now().millisecondsSinceEpoch}';
    await _prefs.setString('profile_avatar_url', cacheBusted);
    return working.copyWith(
      avatar: working.avatar.copyWith(url: cacheBusted),
      authToken: token,
    );
  }

  Future<ProfileData> clearAvatar(ProfileData data) async {
    final token = data.authToken ?? _prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      await _api.deleteAvatar(token);
    }
    await _prefs.remove('profile_avatar_url');
    await _prefs.remove('profile_avatar');
    await _prefs.remove('profile_avatar_b64');
    final cleared = data.copyWith(
      avatar: const AvatarDetails(),
      authToken: token,
    );
    await cleared.persistSnapshot(_prefs);
    return cleared;
  }

  Future<ProfileData> saveBanner(ProfileData data, XFile file) async {
    final token = data.authToken ?? _prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      return _saveBannerOffline(data, file);
    }

    final updated = await _uploadBanner(token, data, file);
    await updated.persistSnapshot(_prefs);
    return updated;
  }

  Future<ProfileData> _saveBannerOffline(ProfileData data, XFile file) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await _prefs.setString('profile_banner_b64', base64Encode(bytes));
      await _prefs.remove('profile_banner');
      final updated = data.copyWith(
        banner: data.banner.copyWith(bytes: bytes, localPath: null),
      );
      await updated.persistSnapshot(_prefs);
      return updated;
    }
    await _prefs.setString('profile_banner', file.path);
    await _prefs.remove('profile_banner_b64');
    final updated = data.copyWith(
      banner: data.banner.copyWith(localPath: file.path, bytes: null),
    );
    await updated.persistSnapshot(_prefs);
    return updated;
  }

  Future<ProfileData> _uploadBanner(String token, ProfileData data, XFile file) async {
    String url;
    ProfileData working = data;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await _prefs.setString('profile_banner_b64', base64Encode(bytes));
      await _prefs.remove('profile_banner');
      final name = file.name.isNotEmpty ? file.name : 'banner.jpg';
      url = await _api.uploadBannerBytes(token, bytes, filename: name);
      working = working.copyWith(banner: working.banner.copyWith(bytes: bytes, localPath: null));
    } else {
      await _prefs.setString('profile_banner', file.path);
      await _prefs.remove('profile_banner_b64');
      final name = file.name.isNotEmpty ? file.name : 'banner.jpg';
      url = await _api.uploadBannerPath(token, file.path, filename: name);
      working = working.copyWith(banner: working.banner.copyWith(localPath: file.path, bytes: null));
    }
    final cacheBusted = '$url?v=${DateTime.now().millisecondsSinceEpoch}';
    await _prefs.setString('profile_banner_url', cacheBusted);
    return working.copyWith(
      banner: working.banner.copyWith(url: cacheBusted),
      authToken: token,
    );
  }

  Future<ProfileData> clearBanner(ProfileData data) async {
    final token = data.authToken ?? _prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      await _api.deleteBanner(token);
    }
    await _prefs.remove('profile_banner_url');
    await _prefs.remove('profile_banner');
    await _prefs.remove('profile_banner_b64');
    final cleared = data.copyWith(
      banner: const BannerDetails(),
      authToken: token,
    );
    await cleared.persistSnapshot(_prefs);
    return cleared;
  }
}

String? _cleanString(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
