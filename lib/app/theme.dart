import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

// ── Keep backward-compat aliases used by other screens ──────────────────────
class AppColors {
  static const primary   = Color(0xFFFFC107);
  static const onPrimary = Color(0xFF0D0D0D);
  static const surface   = Color(0xFF0D0D0D);
  static const onSurface = Color(0xFFFFFFFF);
  static const background= Color(0xFFF5F5F5);
  static const error     = Color(0xFFFF6B6B);
  static const success   = Color(0xFF10B981);
  static const warning   = Color(0xFFF59E0B);

  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey400 = Color(0xFFBDBDBD);
  static const grey500 = Color(0xFF9E9E9E);
  static const grey600 = Color(0xFF757575);
  static const grey800 = Color(0xFF212121);
}

class AppTextStyles {
  static TextStyle display(double size, {Color color = AppColors.onSurface}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
        height: 1.05,
        letterSpacing: -1.5,
      );

  static TextStyle body(double size, {Color color = AppColors.onSurface, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.5,
      );

  static TextStyle label(double size, {Color color = AppColors.onSurface}) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  THEME BUILDER
// ─────────────────────────────────────────────────────────────────────────────

ThemeData buildAppTheme([Brightness brightness = Brightness.light]) {
  final isDark = brightness == Brightness.dark;

  final bg       = isDark ? RukuninColors.darkBg       : RukuninColors.lightBg;
  final surface  = isDark ? RukuninColors.darkSurface  : RukuninColors.lightSurface;
  final surface2 = isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2;
  final border   = isDark ? RukuninColors.darkBorder   : RukuninColors.lightBorder;
  final textPri  = isDark ? RukuninColors.darkTextPrimary   : RukuninColors.lightTextPrimary;
  final textSec  = isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary;
  final textTer  = isDark ? RukuninColors.darkTextTertiary  : RukuninColors.lightTextTertiary;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: RukuninColors.brandGreen,
    onPrimary: Colors.white,
    primaryContainer: isDark
        ? RukuninColors.brandGreen.withValues(alpha: 0.15)
        : RukuninColors.brandGreen.withValues(alpha: 0.10),
    onPrimaryContainer: isDark ? RukuninColors.brandGreen : const Color(0xFF004D26),
    secondary: RukuninColors.brandTeal,
    onSecondary: Colors.white,
    secondaryContainer: isDark
        ? RukuninColors.brandTeal.withValues(alpha: 0.15)
        : RukuninColors.brandTeal.withValues(alpha: 0.10),
    onSecondaryContainer: isDark ? RukuninColors.brandTeal : const Color(0xFF00363A),
    error: RukuninColors.error,
    onError: Colors.white,
    errorContainer: isDark ? RukuninColors.errorBgDark : RukuninColors.errorBg,
    onErrorContainer: isDark ? RukuninColors.errorTextDark : RukuninColors.errorText,
    surface: surface,
    onSurface: textPri,
    surfaceContainerHighest: surface2,
    outline: border,
    outlineVariant: isDark ? RukuninColors.darkBorderSub : RukuninColors.lightBorderSub,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: bg,
    fontFamily: GoogleFonts.poppins().fontFamily,

    // ── AppBar ──────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPri,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: textPri,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: textPri, size: 22),
      actionsIconTheme: IconThemeData(color: textSec, size: 22),
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      shape: Border(
        bottom: BorderSide(color: border, width: 0.5),
      ),
    ),

    // ── BottomNavigation ─────────────────────────────────────────────────────
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: RukuninColors.brandGreen,
      unselectedItemColor: textTer,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w500),
    ),

    // ── NavigationBar (M3) ───────────────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: RukuninColors.brandGreen.withValues(alpha: 0.12),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: RukuninColors.brandGreen, size: 22);
        }
        return IconThemeData(color: textTer, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: RukuninColors.brandGreen,
          );
        }
        return GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w500, color: textTer,
        );
      }),
      elevation: 0,
      shadowColor: Colors.transparent,
    ),

    // ── Card ─────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),

    // ── Input ─────────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RukuninColors.brandGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RukuninColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RukuninColors.error, width: 1.5),
      ),
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: textTer),
      labelStyle: GoogleFonts.poppins(fontSize: 14, color: textSec),
      errorStyle: GoogleFonts.poppins(
          fontSize: 12, color: RukuninColors.error),
    ),

    // ── ElevatedButton ────────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: RukuninColors.brandGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: isDark
            ? const Color(0xFF1C2330)
            : const Color(0xFFE4E7ED),
        disabledForegroundColor: textTer,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    // ── OutlinedButton ────────────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPri,
        side: BorderSide(color: border, width: 1),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    // ── TextButton ────────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: RukuninColors.brandGreen,
        textStyle: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    // ── FloatingActionButton ─────────────────────────────────────────────────
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: RukuninColors.brandGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    // ── Chip ─────────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: surface2,
      selectedColor: RukuninColors.brandGreen.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w500, color: textSec),
      side: BorderSide(color: border, width: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),

    // ── TabBar ────────────────────────────────────────────────────────────────
    tabBarTheme: TabBarThemeData(
      labelColor: RukuninColors.brandGreen,
      unselectedLabelColor: textSec,
      indicatorColor: RukuninColors.brandGreen,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w500),
      dividerColor: border,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    ),

    // ── Divider ───────────────────────────────────────────────────────────────
    dividerTheme: DividerThemeData(
      color: border,
      thickness: 0.5,
      space: 0,
    ),

    // ── ListTile ─────────────────────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      tileColor: surface,
      titleTextStyle: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: textPri),
      subtitleTextStyle: GoogleFonts.poppins(
          fontSize: 13, color: textSec),
      iconColor: textSec,
      minLeadingWidth: 0,
    ),

    // ── Dialog ────────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border, width: 0.5),
      ),
      titleTextStyle: GoogleFonts.poppins(
          fontSize: 17, fontWeight: FontWeight.w700, color: textPri),
      contentTextStyle: GoogleFonts.poppins(
          fontSize: 14, color: textSec, height: 1.5),
    ),

    // ── SnackBar ──────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark
          ? const Color(0xFF1C2330)
          : const Color(0xFF0D1117),
      contentTextStyle: GoogleFonts.poppins(
          fontSize: 14, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),

    // ── Switch ────────────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return isDark ? const Color(0xFF4A5568) : const Color(0xFFD1D5DB);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return RukuninColors.brandGreen;
        }
        return isDark ? const Color(0xFF1C2330) : const Color(0xFFE4E7ED);
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    // ── Checkbox ──────────────────────────────────────────────────────────────
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return RukuninColors.brandGreen;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: BorderSide(color: border, width: 1.5),
    ),

    // ── ProgressIndicator ─────────────────────────────────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: RukuninColors.brandGreen,
      circularTrackColor: Colors.transparent,
      linearTrackColor: Colors.transparent,
    ),

    // ── Dropdown ─────────────────────────────────────────────────────────────
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
      ),
    ),

    // ── BottomSheet ───────────────────────────────────────────────────────────
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: true,
      dragHandleColor: border,
      dragHandleSize: const Size(40, 4),
    ),

    // ── PopupMenu ─────────────────────────────────────────────────────────────
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border, width: 0.5),
      ),
      textStyle: GoogleFonts.poppins(fontSize: 14, color: textPri),
    ),

    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ),
  );
}
