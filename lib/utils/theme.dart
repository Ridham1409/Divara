import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DivaraTheme {
  // COLORS
  static const Color gold = Color(0xFFD4AF37);
  static const Color primaryColor = Color(0xFF832A2A); // 🔥 AA COLOR MISSING HATO (Tanishq Maroon)
  static const Color lightBg = Color(0xFFFFFDF5); // Cream background
  static const Color darkBg = Color(0xFF121212);

  // TEXT STYLES
  static TextStyle get brandTitleStyle => GoogleFonts.cinzel(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
  );

  // THEMES
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    primaryColor: primaryColor,
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: primaryColor), // Appbar Icons Maroon
    ),
    colorScheme: const ColorScheme.light(primary: primaryColor, secondary: gold),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    primaryColor: primaryColor,
    cardColor: const Color(0xFF1E1E1E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: gold),
    ),
    colorScheme: const ColorScheme.dark(primary: gold, secondary: primaryColor),
  );
}