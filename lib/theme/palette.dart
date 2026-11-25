import 'dart:ui' show Color;

/// "Zmierzch" palette from the first mockups.
abstract final class Palette {
  static const night = Color(0xFF110F1C); // page ground
  static const ink = Color(0xFF1D1A2F); // outlines, screen ground
  static const plum = Color(0xFF3B2D5C); // panels
  static const plumDeep = Color(0xFF2A2244); // deep panels
  static const lavender = Color(0xFFB9A7E8); // muted text
  static const paper = Color(0xFFF4EFFF); // main text
  static const mint = Color(0xFF5FD3A5); // on time, Done
  static const mintDark = Color(0xFF2F9C78);
  static const amber = Color(0xFFFFB347); // mascot, +5, warnings
  static const amberDark = Color(0xFFD9822B);
  static const tomato = Color(0xFFFF5E5B); // late
  static const sky = Color(0xFF7EC8E3); // info
  static const gold = Color(0xFFFFE066); // points
  static const black = Color(0xFF000000);
}

/// Pixelify Sans draws 5 like S and Z like 2, so any line of UI text
/// that carries numbers uses VT323 at a slightly larger size.
abstract final class NumText {
  static const size = 21.0;
}

/// Font families bundled in assets/fonts (all OFL, all with Polish glyphs).
abstract final class Fonts {
  static const logo = 'PressStart2P'; // logo, big headings
  static const ui = 'PixelifySans'; // interface
  static const numbers = 'VT323'; // clocks and timers
}
