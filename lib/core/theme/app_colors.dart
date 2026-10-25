import 'package:flutter/material.dart';

/// Semantic colors for one brightness. Every text color meets WCAG AA
/// (4.5:1) on both the page and card backgrounds; see app_colors_test.dart.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.onDanger,
    required this.outline,
    required this.outlineStrong,
    required this.subtle,
  });

  static const dark = AppColors(
    brightness: Brightness.dark,
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    text: Color(0xFFFFFFFF),
    textMuted: Color(0xFFA6B0C0),
    // A lighter salmon than the drawing's, so text in it stays readable.
    accent: Color(0xFFF7A072),
    onAccent: Color(0xFF2A1810),
    danger: Color(0xFFF87171),
    onDanger: Color(0xFF000000),
    outline: Color(0x1AFFFFFF),
    outlineStrong: Color(0x3DFFFFFF),
    subtle: Color(0x0AFFFFFF),
  );

  /// Rice-white pages and a deeper salmon that stays readable on them.
  static const light = AppColors(
    brightness: Brightness.light,
    background: Color(0xFFFFF7F0),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1E293B),
    textMuted: Color(0xFF5B6472),
    accent: Color(0xFFA9471F),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFB91C1C),
    onDanger: Color(0xFFFFFFFF),
    outline: Color(0x1A1E293B),
    outlineStrong: Color(0x3D1E293B),
    subtle: Color(0x0A1E293B),
  );

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color text;

  /// Secondary text and inactive icons.
  final Color textMuted;
  final Color accent;

  /// Text and icons placed on [accent].
  final Color onAccent;

  /// Destructive actions and errors.
  final Color danger;

  /// Text and icons placed on [danger].
  final Color onDanger;

  /// Hairlines: card borders, dividers, chart grids.
  final Color outline;

  /// Borders that must be seen: inputs, drag handles, segmented buttons.
  final Color outlineStrong;

  /// Barely-there fills, such as the track behind chart bars.
  final Color subtle;

  @override
  AppColors copyWith({
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? text,
    Color? textMuted,
    Color? accent,
    Color? onAccent,
    Color? danger,
    Color? onDanger,
    Color? outline,
    Color? outlineStrong,
    Color? subtle,
  }) => AppColors(
    brightness: brightness ?? this.brightness,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    outline: outline ?? this.outline,
    outlineStrong: outlineStrong ?? this.outlineStrong,
    subtle: subtle ?? this.subtle,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      text: mix(text, other.text),
      textMuted: mix(textMuted, other.textMuted),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      danger: mix(danger, other.danger),
      onDanger: mix(onDanger, other.onDanger),
      outline: mix(outline, other.outline),
      outlineStrong: mix(outlineStrong, other.outlineStrong),
      subtle: mix(subtle, other.subtle),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
