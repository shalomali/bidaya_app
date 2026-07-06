import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Brand Colors (Navy Style Guide)
  static const Color primary = Color(0xFF1A227F); 
  static const Color secondary = Color(0xFF0DF2DF); // Keeping the cyan as a bright secondary accent
  
  // Background Colors
  static const Color background = Color(0xFFF6F6F8);
  static const Color surface = Colors.white;
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFD1D5DB); // Lighter gray for better contrast
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color backgroundDark = Color(0xFF111827);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Semantic Getters
  static Color getAdaptiveTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimary;
  }

  static Color getAdaptiveTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondary;
  }

  static Color getAdaptiveSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? surfaceDark : surface;
  }
  
  static Color getAdaptiveBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? backgroundDark : background;
  }

  static Color getAdaptivePrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? secondary : primary;
  }

  static Color getAdaptiveTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimary;
  }

  static Color getAdaptiveIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : textPrimary;
  }

  static Color getAdaptiveSuccess(BuildContext context) {
    return success;
  }

  static Color getAdaptiveError(BuildContext context) {
    return error;
  }

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.manropeTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE0E0FF),
        onPrimaryContainer: primary,
        secondary: secondary,
        onSecondary: Color(0xFF003735),
        secondaryContainer: Color(0xFF97F4EE),
        onSecondaryContainer: Color(0xFF00201E),
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerLow: Color(0xFFF7F2FA),
        surfaceContainer: Color(0xFFF3EDF7),
        surfaceContainerHigh: Color(0xFFECE6F0),
        surfaceContainerHighest: Color(0xFFE6E0E9),
        error: error,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        titleTextStyle: GoogleFonts.manrope(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: const StadiumBorder(), // Expressive 2025 Standard
          elevation: 0,
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          shape: const StadiumBorder(), // Expressive 2025 Standard
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28), // Expressive rounding
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        labelStyle: GoogleFonts.manrope(color: textSecondary),
        floatingLabelStyle: GoogleFonts.manrope(color: primary, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(28)), // Expressive
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        color: surface,
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineSmall: GoogleFonts.manrope(fontSize: 24, color: textPrimary, fontWeight: FontWeight.w800),
        titleLarge: GoogleFonts.manrope(fontSize: 22, color: textPrimary, fontWeight: FontWeight.w700),
        bodyLarge: GoogleFonts.manrope(fontSize: 16, color: textPrimary, height: 1.5),
        bodyMedium: GoogleFonts.manrope(fontSize: 14, color: textSecondary),
        bodySmall: GoogleFonts.manrope(fontSize: 12, color: textSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: secondary, 
        onPrimary: Color(0xFF003735),
        primaryContainer: Color(0xFF00504D),
        onPrimaryContainer: Color(0xFF97F4EE),
        secondary: secondary,
        onSecondary: Color(0xFF003735),
        surface: Color(0xFF1A1C1E), // Deep Charcoal, not pure black
        onSurface: Color(0xFFE2E2E6),
        surfaceContainerLow: Color(0xFF1A1C1E),
        surfaceContainer: Color(0xFF202226),
        surfaceContainerHigh: Color(0xFF2A2C30),
        error: error,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1113), // Deep immersive background
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F1113),
        foregroundColor: textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 2,
        titleTextStyle: GoogleFonts.manrope(
          color: textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Color(0xFF003735),
          minimumSize: const Size(double.infinity, 56),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          side: const BorderSide(color: secondary, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1C1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: secondary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        labelStyle: GoogleFonts.manrope(color: textSecondaryDark),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
        color: Color(0xFF1A1C1E),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0F1113),
        selectedItemColor: secondary,
        unselectedItemColor: Color(0xFF8E9199),
      ),
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
        headlineSmall: GoogleFonts.manrope(fontSize: 24, color: textPrimaryDark, fontWeight: FontWeight.w800),
        titleLarge: GoogleFonts.manrope(fontSize: 22, color: textPrimaryDark, fontWeight: FontWeight.w700),
        bodyLarge: GoogleFonts.manrope(fontSize: 16, color: textPrimaryDark, height: 1.5),
        bodyMedium: GoogleFonts.manrope(fontSize: 14, color: textSecondaryDark),
        bodySmall: GoogleFonts.manrope(fontSize: 12, color: textSecondaryDark),
      ),
    );
  }
}
