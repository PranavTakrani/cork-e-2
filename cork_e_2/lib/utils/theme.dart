import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RetroTheme {
  static const Color corkBackground = Color(0xFFD4A373);
  static const Color yellowSticky = Color(0xFFFFF59D);
  static const Color blueSticky = Color(0xFF81D4FA);
  static const Color whiteNote = Color(0xFFFFFDF7);
  static const Color blackMarker = Color(0xFF212121);
  static const Color redPin = Color(0xFFE57373);
  static const Color tape = Color(0xFFF5F5DC);

  static ThemeData get theme {
    return ThemeData(
      primarySwatch: Colors.brown,
      scaffoldBackgroundColor: corkBackground,
      fontFamily: GoogleFonts.kalam().fontFamily,
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.permanentMarker(
          fontSize: 32,
          color: blackMarker,
        ),
        headlineMedium: GoogleFonts.kalam(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: blackMarker,
        ),
        bodyLarge: GoogleFonts.kalam(
          fontSize: 18,
          color: blackMarker,
        ),
        bodyMedium: GoogleFonts.kalam(
          fontSize: 16,
          color: blackMarker,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blackMarker,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.kalam(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: GoogleFonts.kalam(
          color: blackMarker.withOpacity(0.7),
        ),
      ),
    );
  }
}