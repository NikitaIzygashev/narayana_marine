import 'package:flutter/material.dart';

class AppTheme {
  static const navy = Color(0xFF062D3A);
  static const sea = Color(0xFF0B6774);
  static const aqua = Color(0xFF8FE3DF);
  static const sand = Color(0xFFF4EFE7);
  static const ink = Color(0xFF13272C);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: sea,
      brightness: Brightness.light,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.6,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(height: 1.55),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFB6C2C4)),
        ),
      ),
    );
  }
}
