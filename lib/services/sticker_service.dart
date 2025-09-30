import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Sticker {
  final String name;
  final String? asset; // filename inside assets/stickers
  final String? url;   // remote PNG
  const Sticker({required this.name, this.asset, this.url});
}

class StickerService {
  static const String assetFolder = 'assets/stickers/';
  static const String manifestPath = 'assets/stickers/manifest.json';

  Future<List<Sticker>> loadStickers() async {
    final locals = await _loadLocalStickerNames();
    if (locals.isNotEmpty) {
      return locals.map((n) => Sticker(name: n, asset: n)).toList();
    }
    // No fallback: UI will show hint to add PNGs.
    return const <Sticker>[];
  }

  Future<List<String>> _loadLocalStickerNames() async {
    try {
      final s = await rootBundle.loadString(manifestPath);
      final list = jsonDecode(s);
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return const <String>[];
  }
}