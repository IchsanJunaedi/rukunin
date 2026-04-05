import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RUKUNIN — Typography Scale
// ─────────────────────────────────────────────────────────────────────────────

abstract class RukuninText {

  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle displayLg({Color? color}) => RukuninFonts.pjs(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    height: 1.1,
    color: color,
  );

  static TextStyle displayMd({Color? color}) => RukuninFonts.pjs(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    height: 1.15,
    color: color,
  );

  // ── Heading ───────────────────────────────────────────────────────────────
  static TextStyle h1({Color? color}) => RukuninFonts.pjs(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
    color: color,
  );

  static TextStyle h2({Color? color}) => RukuninFonts.pjs(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
    color: color,
  );

  static TextStyle h3({Color? color}) => RukuninFonts.pjs(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
    color: color,
  );

  static TextStyle h4({Color? color}) => RukuninFonts.pjs(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
    color: color,
  );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle bodyLg({Color? color}) => RukuninFonts.pjs(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.6,
    color: color,
  );

  static TextStyle body({Color? color}) => RukuninFonts.pjs(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.55,
    color: color,
  );

  static TextStyle bodySm({Color? color}) => RukuninFonts.pjs(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: color,
  );

  // ── Label / UI ────────────────────────────────────────────────────────────
  static TextStyle labelLg({Color? color}) => RukuninFonts.pjs(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle label({Color? color}) => RukuninFonts.pjs(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle labelSm({Color? color}) => RukuninFonts.pjs(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: color,
  );

  // ── Caption ───────────────────────────────────────────────────────────────
  static TextStyle caption({Color? color}) => RukuninFonts.pjs(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: color,
  );

  static TextStyle captionBold({Color? color}) => RukuninFonts.pjs(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: color,
  );

  // ── Overline ──────────────────────────────────────────────────────────────
  static TextStyle overline({Color? color}) => RukuninFonts.pjs(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: color,
  );

  // ── Numeric ───────────────────────────────────────────────────────────────
  static TextStyle numericHero({Color? color}) => RukuninFonts.pjs(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    height: 1.0,
    color: color,
  );

  static TextStyle numericLg({Color? color}) => RukuninFonts.pjs(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: color,
  );

  static TextStyle numericMd({Color? color}) => RukuninFonts.pjs(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: color,
  );
}
