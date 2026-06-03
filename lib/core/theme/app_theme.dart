import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme(Color colorSeed) {
    return ThemeData(
      colorSchemeSeed: colorSeed,
      brightness: Brightness.light,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData darkTheme(Color colorSeed) {
    return ThemeData(
      colorSchemeSeed: colorSeed,
      brightness: Brightness.dark,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
