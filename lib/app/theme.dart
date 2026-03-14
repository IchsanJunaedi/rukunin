import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// RUKUNIN — Design Tokens
// ============================================================
class AppColors {
  static const primary = Color(0xFFFFC107);   // Kuning utama
  static const onPrimary = Color(0xFF0D0D0D); // Teks di atas kuning
  static const surface = Color(0xFF0D0D0D);   // Hitam (surface/card)
  static const onSurface = Color(0xFFFFFFFF); // Teks di atas hitam
  static const background = Color(0xFFF5F5F5);
  static const error = Color(0xFFFF6B6B);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);

  // Shades
  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey400 = Color(0xFFBDBDBD);
  static const grey500 = Color(0xFF9E9E9E);
  static const grey600 = Color(0xFF757575);
  static const grey800 = Color(0xFF212121);
}

class AppTextStyles {
  // Display — Playfair Display (headline besar)
  static TextStyle display(double size, {Color color = AppColors.onSurface}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
        height: 1.05,
        letterSpacing: -1.5,
      );

  // Body — Plus Jakarta Sans
  static TextStyle body(double size, {Color color = AppColors.onSurface, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.5,
      );

  static TextStyle label(double size, {Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
      );
}

// ============================================================
// THEME
// ============================================================
ThemeData buildAppTheme() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.surface,
      onSecondary: AppColors.onSurface,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.grey100,
      onSurface: AppColors.grey800,
    ),
    scaffoldBackgroundColor: AppColors.grey100,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.grey100,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppColors.grey800),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.grey800,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.white.withValues(alpha: 0.35),
      selectedLabelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.grey200,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        elevation: 0,
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.grey200,
      selectedColor: AppColors.primary,
      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      side: BorderSide.none,
    ),
  );
}
