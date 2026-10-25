import 'package:flutter/material.dart';

class SalonTheme {
  static const ink = Color(0xFF292421);
  static const ivory = Color(0xFFFAF7F2);
  static const blush = Color(0xFFB57872);
  static const taupe = Color(0xFF786960);
  static const line = Color(0xFFE9E1D9);
  static const radius = 16.0;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: blush,
      brightness: Brightness.light,
      surface: ivory,
      primary: ink,
      secondary: blush,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ivory,
      appBarTheme: const AppBarTheme(
        backgroundColor: ivory,
        foregroundColor: ink,
        centerTitle: false,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Georgia', fontSize: 38, color: ink),
        headlineMedium: TextStyle(fontFamily: 'Georgia', fontSize: 30, color: ink),
        titleLarge: TextStyle(fontFamily: 'Georgia', fontSize: 24, color: ink),
        bodyLarge: TextStyle(fontSize: 16, color: ink),
        bodyMedium: TextStyle(fontSize: 14, color: ink),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
