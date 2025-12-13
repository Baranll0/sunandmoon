import 'package:flutter/material.dart';

/// App Theme - Minimalist "Paper & Ink" aesthetic
class AppTheme {
  // Color Palette
  static const Color backgroundCream = Color(0xFFFDFBF7);
  static const Color sunOrange = Color(0xFFFF8C42);
  static const Color moonBlue = Color(0xFF4A90E2);
  static const Color errorRed = Color(0xFFFF6B6B);
  static const Color inkDark = Color(0xFF2C3E50);
  static const Color inkLight = Color(0xFF7F8C8D);
  static const Color gridLine = Color(0xFFE0E0E0);
  static const Color hintYellow = Color(0xFFFFE66D);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sunOrange,
        brightness: Brightness.light,
        primary: sunOrange,
        secondary: moonBlue,
        error: errorRed,
        surface: backgroundCream,
        background: backgroundCream,
      ),
      scaffoldBackgroundColor: backgroundCream,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundCream,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: inkDark,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: inkDark,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
        displayMedium: TextStyle(
          color: inkDark,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
        bodyLarge: TextStyle(
          color: inkDark,
          fontSize: 16,
          fontFamily: 'Roboto',
        ),
        bodyMedium: TextStyle(
          color: inkLight,
          fontSize: 14,
          fontFamily: 'Roboto',
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

