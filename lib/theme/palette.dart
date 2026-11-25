import 'dart:ui' show Color, FontVariation, FontWeight;

import 'package:material_ui/material_ui.dart' show TextStyle;

/// Palette from the end-to-end design (v0.4): calm, mature dark UI.
/// Pixel art only lives inside scenes and sprites.
abstract final class Palette {
  static const bg = Color(0xFF080D17); // page ground
  static const app = Color(0xFF0D1422); // screen ground
  static const card = Color(0xFF141D2F);
  static const card2 = Color(0xFF1A2540);
  static const line = Color(0xFF24314D);
  static const tabs = Color(0xFF0B111D);
  static const text = Color(0xFFECF2FB);
  static const muted = Color(0xFF93A3BF);
  static const faint = Color(0xFF5F6F8C);
  static const gold = Color(0xFFFFD27A); // points, primary action
  static const goldStrong = Color(0xFFF3B44B);
  static const teal = Color(0xFF62DCC4); // on time, Done
  static const rose = Color(0xFFFF8A80); // late (soft, never alarming)
  static const lilac = Color(0xFFB7A4FF); // evolution
  static const onAccent = Color(0xFF0B1220); // text on gold/teal buttons
}

/// Font families bundled in assets/fonts (both SIL OFL, with Polish glyphs).
abstract final class Fonts {
  static const text = 'Lexend'; // all UI text
  static const numbers = 'VT323'; // clocks, durations, points
}

/// Text style with a weight that also works for the variable Lexend font
/// (sets the `wght` axis, not just the synthetic weight).
TextStyle ts({
  double size = 15,
  int weight = 400,
  Color color = Palette.text,
  double? height,
  String family = Fonts.text,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.values[(weight ~/ 100 - 1).clamp(0, 8)],
    fontVariations: family == Fonts.text
        ? [FontVariation.weight(weight.toDouble())]
        : null,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

/// VT323 numbers ("09:55", "+143").
TextStyle numStyle(double size, {Color color = Palette.text}) =>
    ts(size: size, family: Fonts.numbers, color: color, height: 0.95);
