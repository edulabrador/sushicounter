import 'package:flutter/material.dart';

/// Semantic colors for the dark theme. Every text color meets WCAG AA
/// (4.5:1) on both the page and card backgrounds; see app_colors_test.dart.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.danger,
  });

  static const dark = AppColors(
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    text: Color(0xFFFFFFFF),
    textMuted: Color(0xFFA6B0C0),
    accent: Color(0xFFFFA726),
    danger: Color(0xFFF87171),
  );

  final Color background;
  final Color surface;
  final Color text;

  /// Secondary text and inactive icons.
  final Color textMuted;
  final Color accent;

  /// Destructive actions and errors.
  final Color danger;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? text,
    Color? textMuted,
    Color? accent,
    Color? danger,
  }) => AppColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    accent: accent ?? this.accent,
    danger: danger ?? this.danger,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
