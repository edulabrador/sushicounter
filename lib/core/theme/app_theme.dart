import 'package:flutter/material.dart';

import 'app_colors.dart';

export 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    const colors = AppColors.dark;
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: colors.accent,
      colorScheme: ColorScheme.dark(
        primary: colors.accent,
        secondary: const Color(0xFFFFCC80),
        surface: colors.surface,
        error: colors.danger,
      ),
      scaffoldBackgroundColor: colors.background,
      extensions: const [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textMuted),
        titleTextStyle: TextStyle(
          color: colors.text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: colors.text,
          fontSize: 96,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: colors.text, fontSize: 18),
        bodyMedium: TextStyle(color: colors.textMuted, fontSize: 14),
        titleLarge: TextStyle(
          color: colors.text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: colors.accent,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
