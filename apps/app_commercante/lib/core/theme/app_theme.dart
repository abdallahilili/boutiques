import 'package:flutter/material.dart';

/// Thème clair/sombre : gros boutons et zones tactiles, lisibles pour des utilisatrices peu techniques.
/// La couleur principale vient du réglage « Apparence » (couleur d'origine par défaut).
abstract final class AppTheme {
  static const defaultSeed = Color(0xFF8A3B5C);

  static ThemeData light([Color seed = defaultSeed]) => _build(Brightness.light, seed);
  static ThemeData dark([Color seed = defaultSeed]) => _build(Brightness.dark, seed);

  static ThemeData _build(Brightness brightness, Color seed) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      navigationBarTheme: const NavigationBarThemeData(height: 68),
    );
  }
}
