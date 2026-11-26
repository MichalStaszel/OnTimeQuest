import 'dart:math' as math;
import 'dart:typed_data';

import 'sprites.dart';

/// 4x4 Bayer matrix for ordered dithering (the "retro" gradient look).
const _bayer = [
  [0, 8, 2, 10],
  [12, 4, 14, 6],
  [3, 11, 1, 9],
  [15, 7, 13, 5],
];
double _b4(int x, int y) => (_bayer[y & 3][x & 3] + 0.5) / 16;

typedef Rgb = (int, int, int);

Rgb hex(String h) {
  final v = int.parse(h.replaceFirst('#', ''), radix: 16);
  return ((v >> 16) & 255, (v >> 8) & 255, v & 255);
}

/// Deterministic random numbers (mulberry32), so a scene looks the same
/// every time it is drawn.
double Function() seededRandom(int seed) {
  var s = seed & 0xFFFFFFFF;
  int imul(int a, int b) => (a * b) & 0xFFFFFFFF;
  return () {
    s = (s + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = imul(s ^ (s >> 15), 1 | s);
    t = ((t + imul(t ^ (t >> 7), 61 | t)) & 0xFFFFFFFF) ^ t;
    return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296;
  };
}

/// A small RGBA pixel buffer with the drawing helpers the design's scene
/// engine uses: dithered gradients, soft light glows, sprites, lines.
class PixelCanvas {
  PixelCanvas(this.w, this.h) : rgba = Uint8List(w * h * 4);

  final int w;
  final int h;
  final Uint8List rgba;

  void set(num fx, num fy, Rgb c) {
    final x = fx.floor(), y = fy.floor();
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    final i = (y * w + x) * 4;
    rgba[i] = c.$1;
    rgba[i + 1] = c.$2;
    rgba[i + 2] = c.$3;
    rgba[i + 3] = 255;
  }

  Rgb get(int x, int y) {
    x = x.clamp(0, w - 1);
    y = y.clamp(0, h - 1);
    final i = (y * w + x) * 4;
    return (rgba[i], rgba[i + 1], rgba[i + 2]);
  }

  void rect(num x, num y, num rw, num rh, String color) {
    final c = hex(color);
    for (var j = y.floor(); j < (y + rh).floor(); j++) {
      for (var i = x.floor(); i < (x + rw).floor(); i++) {
        set(i, j, c);
      }
    }
  }

  /// Vertical gradient through [colors], dithered between steps.
  void gradient(List<String> colors, int x0, int y0, int gw, int gh) {
    final cs = colors.map(hex).toList();
    for (var y = y0; y < y0 + gh; y++) {
      final t = (y - y0) / gh * (cs.length - 1);
      final k = t.floor();
      final f = t - k;
      for (var x = x0; x < x0 + gw; x++) {
        set(x, y, f > _b4(x, y) ? cs[math.min(k + 1, cs.length - 1)] : cs[k]);
      }
    }
  }

  /// Soft, quantised light around (cx, cy).
  void glow(num cx, num cy, num r, String color, double strength) {
    final c = hex(color);
    for (var y = math.max(0, (cy - r).floor()); y < math.min(h, cy + r); y++) {
      for (
        var x = math.max(0, (cx - r).floor());
        x < math.min(w, cx + r);
        x++
      ) {
        final d = math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)) / r;
        if (d >= 1) continue;
        final a = (1 - d) * (1 - d) * strength;
        final q = (a * 3 + _b4(x, y)).floor() / 3;
        if (q <= 0) continue;
        final p = get(x, y);
        set(x, y, (
          (p.$1 + (c.$1 - p.$1) * q).round(),
          (p.$2 + (c.$2 - p.$2) * q).round(),
          (p.$3 + (c.$3 - p.$3) * q).round(),
        ));
      }
    }
  }

  void sprite(Sprite rows, int x, int y) {
    for (var j = 0; j < rows.length; j++) {
      for (var i = 0; i < rows[j].length; i++) {
        final c = spritePalette[rows[j][i]];
        if (c != null) {
          set(x + i, y + j, (
            (c.r * 255).round(),
            (c.g * 255).round(),
            (c.b * 255).round(),
          ));
        }
      }
    }
  }

  /// A sagging line (wires between poles).
  void line(int x0, int y0, int x1, int y1, double sag, String color) {
    final c = hex(color);
    final n = (x1 - x0).abs() + 1;
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1);
      set(
        x0 + (x1 - x0) * t,
        y0 + (y1 - y0) * t + math.sin(t * math.pi) * sag,
        c,
      );
    }
  }

  /// Value-noise clouds, banded into [colors] with dithering.
  void clouds(
    int seed,
    int x0,
    int y0,
    int cw,
    int ch,
    List<String> colors,
    double threshold,
    double sx,
    double sy,
  ) {
    final noise = _noise2(seed);
    final cs = colors.map(hex).toList();
    for (var y = y0; y < y0 + ch; y++) {
      for (var x = x0; x < x0 + cw; x++) {
        final v = noise(x / sx, y / sy);
        if (v < threshold) continue;
        final t =
            math.min(.999, (v - threshold) / (1 - threshold) * 2.4) * cs.length;
        final k = t.floor();
        final f = t - k;
        set(x, y, cs[math.min(cs.length - 1, f > _b4(x, y) ? k + 1 : k)]);
      }
    }
  }
}

double Function(double, double) _noise2(int seed) {
  final r = seededRandom(seed);
  final p = List.generate(512, (_) => r());
  double hash(int x, int y) => p[((x * 73856093) ^ (y * 19349663)) & 511];
  double smooth(double t) => t * t * (3 - 2 * t);
  double n(double x, double y) {
    final xi = x.floor(), yi = y.floor();
    final xf = x - xi, yf = y - yi;
    final a = hash(xi, yi),
        b = hash(xi + 1, yi),
        c = hash(xi, yi + 1),
        d = hash(xi + 1, yi + 1);
    final u = smooth(xf), v = smooth(yf);
    return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
  }

  return (x, y) =>
      n(x, y) * .55 + n(x * 2.1, y * 2.1) * .3 + n(x * 4.3, y * 4.3) * .15;
}
