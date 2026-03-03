import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.orange,
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Dark navy
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white70),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E293B),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white54,
        elevation: 10,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E293B),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontSize: 96,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: Colors.white70, fontSize: 18),
        bodyMedium: TextStyle(color: Colors.white54, fontSize: 14),
      ),
    );
  }
}
