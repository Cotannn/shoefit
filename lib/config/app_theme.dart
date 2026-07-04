import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _navy = Color(0xFF0B132B);
  static const _teal = Color(0xFF17BEBB);
  static const _surface = Color(0xFFF6F8FB);
  static const _muted = Color(0xFF6C7A89);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _navy,
      brightness: Brightness.light,
      primary: _navy,
      secondary: _teal,
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFE8EDF4),
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme().copyWith(
      headlineLarge: GoogleFonts.sora(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: _navy,
      ),
      headlineMedium: GoogleFonts.sora(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: _navy,
      ),
      titleLarge: GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: _navy,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _muted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: _navy),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE7ECF2)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: _navy,
        side: const BorderSide(color: Color(0xFFD9E0E8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: _navy),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDCE3EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDCE3EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _teal, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: _navy),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          foregroundColor: _navy,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: _navy,
        unselectedItemColor: _muted,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerColor: const Color(0xFFE4EAF1),
    );
  }
}
