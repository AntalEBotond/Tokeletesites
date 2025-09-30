import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UiUtils {
  static Color colorFromHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    var v = hex.replaceAll('#', '');
    if (v.length == 6) v = 'FF$v';
    try {
      return Color(int.parse(v, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  static String hexFromColor(Color c) {
    final v = c.value.toRadixString(16).padLeft(8, '0');
    return '#${v.substring(2)}';
  }

  static String bestTextFor(Color bg) => bg.computeLuminance() > 0.4 ? '#000000' : '#FFFFFF';

  static String normalizeUploadUrl(String url) {
    if (url.isEmpty) return url;
    try {
      final base = ApiService.baseUrl;
      final api = Uri.parse(base);
      final u = Uri.parse(url);

      // Absolute URL case
      if (u.hasScheme) {
        if (u.host != api.host || u.port != api.port) {
          final rel = _extractUploadsRel(u.path) ?? (u.path.startsWith('/') ? u.path : '/${u.path}');
          return Uri.parse('$base$rel').toString();
        }
        return url;
      }

      // Relative URL case (e.g., '/uploads/..' or 'uploads/..')
      final rel = _extractUploadsRel(u.path) ?? (u.path.startsWith('/') ? u.path : '/${u.path}');
      return Uri.parse('$base$rel').toString();
    } catch (_) {}
    return url;
  }

  static String? _extractUploadsRel(String path) {
    final i1 = path.indexOf('/uploads/');
    if (i1 != -1) return path.substring(i1);
    final i2 = path.indexOf('uploads/');
    if (i2 != -1) return '/${path.substring(i2)}';
    return null;
  }
}
