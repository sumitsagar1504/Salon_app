import 'package:flutter/material.dart';

class SalonTheme {
  static const ink = Color(0xFF251F1C);
  static const ivory = Color(0xFFFBF8F3);
  static const paper = Color(0xFFFFFDF9);
  static const blush = Color(0xFFB66F6A);
  static const blushSoft = Color(0xFFF4DEDA);
  static const champagne = Color(0xFFD8B98A);
  static const taupe = Color(0xFF75675F);
  static const muted = Color(0xFF8D817A);
  static const line = Color(0xFFE8DED5);
  static const success = Color(0xFF47745B);
  static const warning = Color(0xFFA36C2C);
  static const danger = Color(0xFFA84F4F);
  static const radius = 18.0;
  static const pageWidth = 1120.0;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: blush,
      brightness: Brightness.light,
      surface: paper,
      primary: ink,
      secondary: blush,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ivory,
      fontFamily: 'Arial',
      appBarTheme: const AppBarTheme(
        backgroundColor: ivory,
        foregroundColor: ink,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 44,
          height: 1.08,
          color: ink,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 38,
          height: 1.12,
          color: ink,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 30,
          height: 1.16,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 24,
          height: 1.2,
          color: ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: ink),
        bodySmall: TextStyle(fontSize: 12, height: 1.4, color: taupe),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: taupe),
        hintStyle: const TextStyle(color: muted),
        prefixIconColor: taupe,
        suffixIconColor: taupe,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: blush, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: line),
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: paper,
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ink,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: blush),
      focusColor: blushSoft,
      hoverColor: blushSoft.withValues(alpha: .45),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
