import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/theme/app_theme.dart';

/// WCAG 2.x relative luminance and contrast ratio.
double _luminance(Color color) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  const colors = AppColors.dark;

  test('text colors meet WCAG AA on page and card backgrounds', () {
    for (final background in [colors.background, colors.surface]) {
      for (final (name, color) in [
        ('text', colors.text),
        ('textMuted', colors.textMuted),
        ('accent', colors.accent),
        ('danger', colors.danger),
      ]) {
        expect(
          contrast(color, background),
          greaterThanOrEqualTo(4.5),
          reason: '$name on $background',
        );
      }
    }
  });

  test('the theme exposes the tokens', () {
    final theme = AppTheme.darkTheme;
    expect(theme.extension<AppColors>(), colors);
    expect(theme.scaffoldBackgroundColor, colors.background);
    expect(theme.colorScheme.error, colors.danger);
  });

  test('the old hard-coded grey failed the same check', () {
    // Documents why white38 was replaced in History.
    final old = Colors.white38;
    final blended = Color.alphaBlend(old, colors.background);
    expect(contrast(blended, colors.background), lessThan(4.5));
  });
}
