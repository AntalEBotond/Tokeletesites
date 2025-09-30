part of 'profile_page.dart';

// ===== Countdown ring painter
class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({
    required this.progress,
    required this.trackColor,
    required this.glowColor,
  });

  final double progress; // 0..1
  final Color trackColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final stroke = math.max(3.0, radius * 0.07);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = glowColor.withOpacity(0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final arcRect = Rect.fromCircle(center: center, radius: radius - stroke / 2);
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2, false, track);

    final sweep = (math.pi * 2) * progress.clamp(0, 1);
    if (sweep > 0) {
      canvas.drawArc(arcRect, -math.pi / 2, sweep, false, active);
    }
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter old) =>
      old.progress != progress || old.trackColor != trackColor || old.glowColor != glowColor;
}

