// Renders the app icons from the in-app nigiri drawing, so the launcher
// icon is the same character as the app. Regenerate with:
//   flutter test tool/icons/render_icons_test.dart
//   python3 tool/icons/make_monochrome.py
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:sushiscore/shared/art/sushi_art.dart';

/// Draws the nigiri, [scale] of the canvas wide, centred, on [background]
/// (transparent when null).
Future<void> _render(
  String path,
  int size, {
  required double scale,
  Color? background,
  double lift = 0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  if (background != null) {
    canvas.drawRect(Offset.zero & Size.square(s), Paint()..color = background);
  }
  final art = s * scale;
  // The drawing sits low in its square (topping starts at 24 %, rice ends at
  // 90 %), so shift it up to centre the visible shape.
  final top = (s - art) / 2 - art * (0.07 + lift);
  paintNigiri(canvas, Rect.fromLTWH((s - art) / 2, top, art, art));
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('render app icons', (tester) async {
    await tester.runAsync(() async {
      const navy = Color(0xFF0F172A);
      expect(AppColors.dark.background, navy);
      // Legacy launcher icon and iOS: full square, the OS applies the mask.
      await _render(
        'assets/icon/app_icon.png',
        1024,
        scale: 0.86,
        background: navy,
      );
      // Adaptive foreground. flutter_launcher_icons adds a 16 % inset, so
      // 0.76 here ends up about 0.52 of the 108dp canvas, inside the safe zone.
      await _render('assets/icon/app_icon_foreground.png', 1024, scale: 0.76);
      // Play Store listing icon.
      await _render(
        'assets/play-store/store-icon.png',
        512,
        scale: 0.86,
        background: navy,
      );
    });
  });
}
