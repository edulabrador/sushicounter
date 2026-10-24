import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The app's kawaii salmon nigiri, shared by the counter button, empty states,
/// records and charts so every screen uses the same character.
enum SushiMood {
  /// Smiling closed eyes: the default, and the tappable counter.
  happy,

  /// Eyes shut and a little "z": nothing here yet.
  sleepy,

  /// Sparkling eyes: a record.
  starry,

  /// Worried brows and a small frown: something went wrong.
  worried,
}

/// Colors of the drawing, also used by the theme so the UI matches it.
abstract final class SushiPalette {
  static const salmon = Color(0xFFF3986A);
  static const salmonStripe = Color(0xFFF9C4A3);
  static const rice = Color(0xFFF8F7F4);
  static const riceShadow = Color(0xFFE6E4DE);
  static const nori = Color(0xFF243528);
  static const faceDark = Color(0xFF3A2A22);
  static const cheek = Color(0xFFF3A6A0);
  static const mouth = Color(0xFF7A3A2E);
  static const tongue = Color(0xFFE87A6B);
  static const sparkle = Color(0xFFFFD93D);
}

/// Draws the nigiri into the square [rect].
void paintNigiri(Canvas canvas, Rect rect, {SushiMood mood = SushiMood.happy}) {
  final s = math.min(rect.width, rect.height);
  canvas.save();
  canvas.translate(
    rect.left + (rect.width - s) / 2,
    rect.top + (rect.height - s) / 2,
  );

  // --- Rice body ---
  final riceRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(s * 0.16, s * 0.40, s * 0.68, s * 0.50),
    Radius.circular(s * 0.20),
  );
  // Soft drop shadow under the rice: the original 6 px at button sizes
  // (96 px and up), scaled down only for small art so it stays crisp.
  canvas.drawRRect(
    riceRect.shift(Offset(0, s * 0.02)),
    Paint()
      ..color = SushiPalette.riceShadow
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.min(6, s / 16)),
  );
  canvas.drawRRect(riceRect, Paint()..color = SushiPalette.rice);

  // --- Salmon topping (drapes over the top of the rice) ---
  final salmonRect = RRect.fromRectAndCorners(
    Rect.fromLTWH(s * 0.12, s * 0.24, s * 0.76, s * 0.26),
    topLeft: Radius.circular(s * 0.16),
    topRight: Radius.circular(s * 0.16),
    bottomLeft: Radius.circular(s * 0.11),
    bottomRight: Radius.circular(s * 0.11),
  );
  canvas.drawRRect(salmonRect, Paint()..color = SushiPalette.salmon);

  // Salmon marbling stripes.
  canvas.save();
  canvas.clipRRect(salmonRect);
  final stripePaint = Paint()
    ..color = SushiPalette.salmonStripe
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
  canvas.drawRRect(noriRect, Paint()..color = SushiPalette.nori);

  // --- Face on the rice (left of the nori) ---
  final eyePaint = Paint()
    ..color = SushiPalette.faceDark
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.022
    ..strokeCap = StrokeCap.round;
  for (final x in [0.30, 0.45]) {
    final center = Offset(s * x, s * 0.60);
    switch (mood) {
      case SushiMood.happy:
        // Happy closed "smiling" eyes (bottom arcs).
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: s * 0.045),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          eyePaint,
        );
      case SushiMood.sleepy:
        canvas.drawLine(
          center.translate(-s * 0.035, s * 0.02),
          center.translate(s * 0.035, s * 0.02),
          eyePaint,
        );
      case SushiMood.starry:
        _paintSparkle(canvas, center.translate(0, s * 0.01), s * 0.05);
      case SushiMood.worried:
        canvas.drawCircle(
          center.translate(0, s * 0.01),
          s * 0.022,
          Paint()..color = SushiPalette.faceDark,
        );
        // Brows tilt up towards the middle of the face.
        final inner = x < 0.375 ? 1.0 : -1.0;
        canvas.drawLine(
          center.translate(-inner * s * 0.04, -s * 0.05),
          center.translate(inner * s * 0.03, -s * 0.075),
          eyePaint,
        );
    }
  }

  // Rosy cheeks.
  final cheekPaint = Paint()..color = SushiPalette.cheek;
  canvas.drawCircle(Offset(s * 0.245, s * 0.685), s * 0.028, cheekPaint);
  canvas.drawCircle(Offset(s * 0.505, s * 0.685), s * 0.028, cheekPaint);

  if (mood == SushiMood.worried) {
    // A small frown.
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.375, s * 0.71), radius: s * 0.035),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      eyePaint,
    );
  } else if (mood == SushiMood.sleepy) {
    // A small calm mouth and a drifting "z".
    canvas.drawCircle(
      Offset(s * 0.375, s * 0.69),
      s * 0.018,
      Paint()..color = SushiPalette.mouth,
    );
    _paintZ(canvas, Offset(s * 0.80, s * 0.14), s * 0.07);
    _paintZ(canvas, Offset(s * 0.91, s * 0.04), s * 0.05);
  } else {
    // Open happy mouth with a little tongue; wider when starry.
    final radius = s * (mood == SushiMood.starry ? 0.06 : 0.05);
    final mouthRect = Rect.fromCircle(
      center: Offset(s * 0.375, s * 0.675),
      radius: radius,
    );
    final mouthPath = Path()
      ..addArc(mouthRect, 0, math.pi)
      ..close();
    canvas.drawPath(mouthPath, Paint()..color = SushiPalette.mouth);
    canvas.save();
    canvas.clipPath(mouthPath);
    canvas.drawCircle(
      Offset(s * 0.375, s * 0.675 + radius * 0.8),
      mood == SushiMood.starry ? radius * 0.45 : s * 0.022,
      Paint()..color = SushiPalette.tongue,
    );
    canvas.restore();
  }
  canvas.restore();
}

void _paintSparkle(Canvas canvas, Offset center, double radius) {
  final inner = radius * 0.32;
  final path = Path();
  for (var i = 0; i < 8; i++) {
    final r = i.isEven ? radius : inner;
    final angle = -math.pi / 2 + i * math.pi / 4;
    final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
    i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
  }
  path.close();
  canvas.drawPath(path, Paint()..color = SushiPalette.sparkle);
  canvas.drawPath(
    path,
    Paint()
      ..color = SushiPalette.faceDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.14
      ..strokeJoin = StrokeJoin.round,
  );
}

void _paintZ(Canvas canvas, Offset topLeft, double size) {
  final path = Path()
    ..moveTo(topLeft.dx, topLeft.dy)
    ..lineTo(topLeft.dx + size, topLeft.dy)
    ..lineTo(topLeft.dx, topLeft.dy + size)
    ..lineTo(topLeft.dx + size, topLeft.dy + size);
  canvas.drawPath(
    path,
    Paint()
      ..color = SushiPalette.rice.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
}

class NigiriPainter extends CustomPainter {
  const NigiriPainter({this.mood = SushiMood.happy});

  final SushiMood mood;

  @override
  void paint(Canvas canvas, Size size) =>
      paintNigiri(canvas, Offset.zero & size, mood: mood);

  @override
  bool shouldRepaint(covariant NigiriPainter oldDelegate) =>
      oldDelegate.mood != mood;
}

/// The nigiri as a decorative widget. Hidden from screen readers unless a
/// [semanticLabel] says what it means.
class SushiArt extends StatelessWidget {
  const SushiArt({
    super.key,
    this.size = 96,
    this.mood = SushiMood.happy,
    this.semanticLabel,
  });

  final double size;
  final SushiMood mood;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final art = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: NigiriPainter(mood: mood)),
    );
    final label = semanticLabel;
    return label == null
        ? ExcludeSemantics(child: art)
        : Semantics(label: label, image: true, child: art);
  }
}
