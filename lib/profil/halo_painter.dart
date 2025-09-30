part of 'profile_page.dart';

// ===== Halo festő (strength támogatással)
class _HaloPainter extends CustomPainter {
  _HaloPainter({required this.rotation, required this.colors, required this.strength});

  final double rotation;
  final List<Color> colors;
  final double strength; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;

    final th = (radius * (0.10 + 0.22 * strength));
    final blur = 4 + 10 * strength;

    final shader = SweepGradient(
      colors: colors + [colors.first],
      startAngle: rotation,
      endAngle: rotation + math.pi * 2,
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = th
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur)
      ..shader = shader;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - th / 2),
      0, math.pi * 2, false, paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HaloPainter old) =>
      old.rotation != rotation || old.colors != colors || old.strength != strength;
}

