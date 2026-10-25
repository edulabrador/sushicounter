import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/art/sushi_art.dart';
import 'app_colors.dart';

export 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme => build(AppColors.dark);
  static ThemeData get lightTheme => build(AppColors.light);

  static ThemeData build(AppColors colors) {
    final dark = colors.brightness == Brightness.dark;
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    return ThemeData(
      brightness: colors.brightness,
      primaryColor: colors.accent,
      colorScheme: (dark ? ColorScheme.dark : ColorScheme.light)(
        primary: colors.accent,
        onPrimary: colors.onAccent,
        secondary: SushiPalette.salmonStripe,
        onSecondary: colors.onAccent,
        surface: colors.surface,
        error: colors.danger,
      ),
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: colors.textMuted),
        titleTextStyle: TextStyle(
          color: colors.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.outline, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          minimumSize: const Size.fromHeight(52),
          shape: rounded,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colors.accent,
          selectedForegroundColor: colors.onAccent,
          foregroundColor: colors.textMuted,
          side: BorderSide(color: colors.outlineStrong),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.accent.withValues(alpha: 0.22),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.accent
                : colors.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colors.text
                : colors.textMuted,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.outline,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded,
      ),
      dividerTheme: DividerThemeData(color: colors.outline),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: TextStyle(
          color: colors.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: colors.textMuted,
          fontSize: 15,
          height: 1.4,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colors.outlineStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.onAccent
              : colors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : colors.background,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.accent,
        textColor: colors.text,
        titleTextStyle: TextStyle(
          color: colors.text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(color: colors.textMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.background,
        // Clearly an example, never mistaken for typed text.
        hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.outlineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.outlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.accent, width: 2),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: colors.text,
          fontSize: 96,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
        bodyLarge: TextStyle(color: colors.text, fontSize: 18),
        bodyMedium: TextStyle(color: colors.textMuted, fontSize: 14),
        titleLarge: TextStyle(
          color: colors.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: colors.text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: colors.accent,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
