import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RUKUNIN — Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

abstract class RukuninColors {
  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color brandGreen = Color(0xFF00C853);
  static const Color brandTeal  = Color(0xFF00BFA5);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandGreen, brandTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFB300);
  static const Color error   = Color(0xFFFF3B30);
  static const Color info    = Color(0xFF0091EA);

  // ── Light mode backgrounds ────────────────────────────────────────────────
  static const Color lightBg       = Color(0xFFF4F6FA);
  static const Color lightSurface  = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF0F2F7);
  static const Color lightBorder   = Color(0xFFE2E8F0);
  static const Color lightBorderSub= Color(0xFFF0F2F7);

  // ── Dark mode backgrounds ─────────────────────────────────────────────────
  static const Color darkBg       = Color(0xFF0D1117);
  static const Color darkSurface  = Color(0xFF141B24);
  static const Color darkSurface2 = Color(0xFF1C2330);
  static const Color darkBorder   = Color(0xFF2A3448);
  static const Color darkBorderSub= Color(0xFF1C2330);

  // ── Light mode text ───────────────────────────────────────────────────────
  static const Color lightTextPrimary   = Color(0xFF0D1117);
  static const Color lightTextSecondary = Color(0xFF4A5568);
  static const Color lightTextTertiary  = Color(0xFF9AA5B4);
  static const Color lightTextInverse   = Color(0xFFF0F4F8);

  // ── Dark mode text ────────────────────────────────────────────────────────
  static const Color darkTextPrimary   = Color(0xFFF0F4F8);
  static const Color darkTextSecondary = Color(0xFF8B96A8);
  static const Color darkTextTertiary  = Color(0xFF4A5568);
  static const Color darkTextInverse   = Color(0xFF0D1117);

  // ── Status light mode ────────────────────────────────────────────────────
  static const Color successBg = Color(0xFFE8FBF0);
  static const Color warningBg = Color(0xFFFFF8E1);
  static const Color errorBg   = Color(0xFFFFEBEA);
  static const Color infoBg    = Color(0xFFE3F4FF);

  static const Color successText = Color(0xFF007A30);
  static const Color warningText = Color(0xFF8A5E00);
  static const Color errorText   = Color(0xFFCC1A10);
  static const Color infoText    = Color(0xFF005C94);

  // ── Status dark mode ─────────────────────────────────────────────────────
  static const Color successBgDark = Color(0xFF0A2416);
  static const Color warningBgDark = Color(0xFF201500);
  static const Color errorBgDark   = Color(0xFF200A09);
  static const Color infoBgDark    = Color(0xFF001B30);

  static const Color successTextDark = Color(0xFF4ADE80);
  static const Color warningTextDark = Color(0xFFFFD54F);
  static const Color errorTextDark   = Color(0xFFFF6B63);
  static const Color infoTextDark    = Color(0xFF40C4FF);
}

abstract class RukuninSpacing {
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xl2  = 24;
  static const double xl3  = 32;
  static const double xl4  = 40;
  static const double xl5  = 48;
  static const double xl6  = 64;
}

abstract class RukuninRadius {
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xl2  = 24;
  static const double full = 999;

  static BorderRadius get xsAll  => BorderRadius.circular(xs);
  static BorderRadius get smAll  => BorderRadius.circular(sm);
  static BorderRadius get mdAll  => BorderRadius.circular(md);
  static BorderRadius get lgAll  => BorderRadius.circular(lg);
  static BorderRadius get xlAll  => BorderRadius.circular(xl);
  static BorderRadius get xl2All => BorderRadius.circular(xl2);
  static BorderRadius get pill   => BorderRadius.circular(full);
}

abstract class RukuninShadow {
  static List<BoxShadow> get sm => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get md => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get lg => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get brand => [
    BoxShadow(
      color: RukuninColors.brandGreen.withValues(alpha: 0.28),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get neonGlow => [
    BoxShadow(
      color: const Color(0xFF00C853).withValues(alpha: 0.35),
      blurRadius: 18,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFF00C853).withValues(alpha: 0.15),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];
}

abstract class RukuninFonts {
  static TextStyle pjs({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
}
