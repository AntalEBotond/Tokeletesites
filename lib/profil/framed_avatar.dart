import 'package:flutter/material.dart';

class FramedAvatar extends StatelessWidget {
  final ImageProvider? image;
  final String name;
  final double radius;
  final String frameStyle;
  final ImageProvider? stickerImage; // PNG sticker drawn on top (asset or network)

  const FramedAvatar({
    super.key,
    required this.image,
    required this.name,
    required this.radius,
    required this.frameStyle,
    this.stickerImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final innerBg = theme.scaffoldBackgroundColor;

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: image,
      child: image == null
          ? Text(
              name.isNotEmpty
                  ? name
                      .split(' ')
                      .map((e) => e.isNotEmpty ? e[0] : '')
                      .take(2)
                      .join()
                  : '?',
              style: const TextStyle(fontSize: 32, color: Colors.black54),
            )
          : null,
    );

    if (frameStyle == 'none') {
      if (stickerImage == null) return avatar;
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          avatar,
          Positioned(
            top: -8,
            child: Image(
              image: stickerImage!,
              height: radius * 0.9,
              filterQuality: FilterQuality.high,
            ),
          )
        ],
      );
    }

    final ring = 6.0;
    final deco = _decorationForStyle(context, frameStyle);

    final frame = Container(
      width: (radius + ring) * 2,
      height: (radius + ring) * 2,
      alignment: Alignment.center,
      decoration: deco,
      padding: EdgeInsets.all(_isThinPadding(frameStyle) ? 3 : 4),
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: innerBg),
          child: avatar,
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        frame,
        if (stickerImage != null)
          Positioned(
            top: -8,
            child: Image(
              image: stickerImage!,
              height: radius * 0.9,
              filterQuality: FilterQuality.high,
            ),
          ),
      ],
    );
  }

  bool _isThinPadding(String style) {
    return style.startsWith('gradient-') || style == 'rainbow';
  }

  BoxDecoration _decorationForStyle(BuildContext context, String s) {
    final theme = Theme.of(context);
    final type = s.contains('-') ? s.split('-').first : s;
    final param = s.contains('-') ? s.substring(s.indexOf('-') + 1) : '';
    switch (type) {
      case 'glow':
        final c = _parseColor(param, theme.colorScheme.primary);
        return BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          boxShadow: [BoxShadow(color: c.withOpacity(0.55), blurRadius: 22, spreadRadius: 2)],
        );
      case 'neon':
        final c = _parseColor(param, const Color(0xFF00FF9C));
        return BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          boxShadow: [BoxShadow(color: c.withOpacity(0.7), blurRadius: 24, spreadRadius: 2)],
          border: Border.all(color: c, width: 2),
        );
      case 'ring':
        final c = _parseColor(param, theme.colorScheme.primary);
        return BoxDecoration(shape: BoxShape.circle, color: c);
      case 'outline':
        final c = _parseColor(param, theme.colorScheme.primary);
        return BoxDecoration(shape: BoxShape.circle, color: Colors.transparent, border: Border.all(color: c, width: 3));
      case 'gradient':
        final g = _gradientByName(param);
        return BoxDecoration(shape: BoxShape.circle, gradient: g);
      case 'rainbow':
        return const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: [
            Color(0xFFFF5252),
            Color(0xFFFFA726),
            Color(0xFFFFEE58),
            Color(0xFF66BB6A),
            Color(0xFF42A5F5),
            Color(0xFF7E57C2),
            Color(0xFFFF5252)
          ]),
        );
      case 'none':
        return const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent);
      default:
        return BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary);
    }
  }

  LinearGradient _gradientByName(String name) {
    switch (name) {
      case 'sunset':
        return const LinearGradient(colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 'ocean':
        return const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]);
      case 'forest':
        return const LinearGradient(colors: [Color(0xFF56ab2f), Color(0xFFa8e063)]);
      case 'violet':
        return const LinearGradient(colors: [Color(0xFF7F00FF), Color(0xFFE100FF)]);
      case 'fire':
        return const LinearGradient(colors: [Color(0xFFFF512F), Color(0xFFF09819)]);
      case 'candy':
        return const LinearGradient(colors: [Color(0xFFf857a6), Color(0xFFFF5858)]);
      case 'berry':
        return const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]);
      case 'sky':
        return const LinearGradient(colors: [Color(0xFF1FA2FF), Color(0xFF12D8FA), Color(0xFFA6FFCB)]);
      case 'mint':
        return const LinearGradient(colors: [Color(0xFF00b09b), Color(0xFF96c93d)]);
      case 'royal':
        return const LinearGradient(colors: [Color(0xFF141E30), Color(0xFF243B55)]);
      case 'rose':
        return const LinearGradient(colors: [Color(0xFFee9ca7), Color(0xFFffdde1)]);
      case 'aurora':
        return const LinearGradient(colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)]);
      case 'citrus':
        return const LinearGradient(colors: [Color(0xFFFDC830), Color(0xFFF37335)]);
      case 'plasma':
        return const LinearGradient(colors: [Color(0xFF12c2e9), Color(0xFFc471ed), Color(0xFFf64f59)]);
      case 'peach':
        return const LinearGradient(colors: [Color(0xFFFFecd2), Color(0xFFfcb69f)]);
      case 'lava':
        return const LinearGradient(colors: [Color(0xFFe52d27), Color(0xFFb31217)]);
      case 'aqua':
        return const LinearGradient(colors: [Color(0xFF13547a), Color(0xFF80d0c7)]);
      case 'steel':
        return const LinearGradient(colors: [Color(0xFF757F9A), Color(0xFFD7DDE8)]);
      case 'gold':
        return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]);
      case 'silver':
        return const LinearGradient(colors: [Color(0xFFB0BEC5), Color(0xFFECEFF1)]);
      case 'bronze':
        return const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFF8D5524)]);
      default:
        return const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFFAB47BC), Color(0xFFFF7043)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
  }

  Color _parseColor(String raw, Color fallback) {
    if (raw.isEmpty) return fallback;
    var v = raw.replaceAll('#', '');
    if (v.length == 6) v = 'FF$v';
    if (v.length != 8) return fallback;
    try {
      return Color(int.parse(v, radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}
