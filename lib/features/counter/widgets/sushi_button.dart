import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A tappable kawaii salmon-nigiri character.
///
/// Recreated in vector (CustomPaint) rather than embedding a bitmap so it
/// scales crisply at any size and carries no asset weight. Each tap fires a
/// little jump-and-flip animation.
class SushiButton extends StatefulWidget {
  const SushiButton({
    super.key,
    required this.onTap,
    required this.onLongPress,
    this.size = 200,
  });

  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double size;

  @override
  State<SushiButton> createState() => _SushiButtonState();
}

class _SushiButtonState extends State<SushiButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    // Replay from the start on every tap, even mid-flight, so rapid tapping
    // keeps hopping.
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final v = _controller.value;
          // Parabolic hop: 0 -> up -> 0.
          final jump = -math.sin(math.pi * v) * (widget.size * 0.18);
          // One full somersault over the hop.
          final spin = v * 2 * math.pi;
          // A touch of squash-and-stretch for bounce.
          final scale = 1 + math.sin(math.pi * v) * 0.06;
          return Transform.translate(
            offset: Offset(0, jump),
            child: Transform.rotate(
              angle: spin,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(painter: _SushiPainter()),
        ),
      ),
    );
  }
}

class _SushiPainter extends CustomPainter {
  // Palette tuned to the friendly-nigiri look.
  static const _salmon = Color(0xFFF3986A);
  static const _salmonStripe = Color(0xFFF9C4A3);
  static const _rice = Color(0xFFF8F7F4);
  static const _riceShadow = Color(0xFFE6E4DE);
  static const _nori = Color(0xFF243528);
  static const _faceDark = Color(0xFF3A2A22);
  static const _cheek = Color(0xFFF3A6A0);
  static const _mouth = Color(0xFF7A3A2E);
  static const _tongue = Color(0xFFE87A6B);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // --- Rice body ---
    final riceRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.16, s * 0.40, s * 0.68, s * 0.50),
      Radius.circular(s * 0.20),
    );
    // Soft drop shadow under the rice.
    canvas.drawRRect(
      riceRect.shift(Offset(0, s * 0.02)),
      Paint()
        ..color = _riceShadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(riceRect, Paint()..color = _rice);

    // --- Salmon topping (drapes over the top of the rice) ---
    final salmonRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(s * 0.12, s * 0.24, s * 0.76, s * 0.26),
      topLeft: Radius.circular(s * 0.16),
      topRight: Radius.circular(s * 0.16),
      bottomLeft: Radius.circular(s * 0.11),
      bottomRight: Radius.circular(s * 0.11),
    );
    canvas.drawRRect(salmonRect, Paint()..color = _salmon);

    // Salmon marbling stripes.
    canvas.save();
    canvas.clipRRect(salmonRect);
    final stripePaint = Paint()
      ..color = _salmonStripe
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.028
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = s * (0.30 + i * 0.055);
      final path = Path()
        ..moveTo(s * 0.13, y)
        ..quadraticBezierTo(s * 0.5, y - s * 0.03, s * 0.87, y);
      canvas.drawPath(path, stripePaint);
    }
    canvas.restore();

    // --- Nori band (vertical wrap, right of the face) ---
    final noriRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.55, s * 0.245, s * 0.16, s * 0.655),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(noriRect, Paint()..color = _nori);

    // --- Face on the rice (left of the nori) ---
    final eyePaint = Paint()
      ..color = _faceDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.022
      ..strokeCap = StrokeCap.round;
    // Happy closed "smiling" eyes (bottom arcs).
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.30, s * 0.60), radius: s * 0.045),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      eyePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.45, s * 0.60), radius: s * 0.045),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      eyePaint,
    );

    // Rosy cheeks.
    final cheekPaint = Paint()..color = _cheek;
    canvas.drawCircle(Offset(s * 0.245, s * 0.685), s * 0.028, cheekPaint);
    canvas.drawCircle(Offset(s * 0.505, s * 0.685), s * 0.028, cheekPaint);

    // Open happy mouth with a little tongue.
    final mouthRect =
        Rect.fromCircle(center: Offset(s * 0.375, s * 0.675), radius: s * 0.05);
    final mouthPath = Path()
      ..addArc(mouthRect, 0, math.pi)
      ..close();
    canvas.drawPath(mouthPath, Paint()..color = _mouth);
    canvas.save();
    canvas.clipPath(mouthPath);
    canvas.drawCircle(
      Offset(s * 0.375, s * 0.715),
      s * 0.022,
      Paint()..color = _tongue,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SushiPainter oldDelegate) => false;
}
