import 'dart:math' as math;

import 'pixel_canvas.dart';
import 'sprites.dart';

/// Atmospheric pixel scenes, ported from the design page's scene engine.
/// The companion is NOT baked in: screens draw it on top so it can animate
/// and change with evolution and items.

/// Where the companion stands in a scene, in scene pixels (feet centre).
class SceneAnchor {
  const SceneAnchor(this.x, this.y);
  final double x;
  final double y;
}

class RoomOptions {
  const RoomOptions({
    this.seed = 3,
    this.plant = false,
    this.lamp = false,
    this.bowl = false,
    this.feast = false,
  });

  final int seed;
  final bool plant;
  final bool lamp;
  final bool bowl;
  final bool feast;

  String get key => 'room-$seed-$plant-$lamp-$bowl-$feast';
}

const roomSize = (160, 96);
const roomAnchor = SceneAnchor(80, 80);

/// Cosy room: wall, window onto a night city, shelf, desk, rug.
/// Bought items (plant, lamp) appear here.
PixelCanvas drawRoom(RoomOptions opt) {
  final (w, h) = roomSize;
  final o = PixelCanvas(w, h);
  final r = seededRandom(opt.seed);
  o.gradient(['#1b2440', '#202b4a', '#25315a'], 0, 0, w, 72);
  for (var x = 0; x < w; x += 8) {
    for (var y = 0; y < 72; y++) {
      if ((y + x) % 3 == 0 && ((y * 7 + x) % 5 == 0)) {
        o.set(x, y, hex('#2a3762'));
      }
    }
  }
  // window with the city at night
  const wx = 96, wy = 8, ww = 50, wh = 44;
  o.gradient(['#071226', '#0c1f3d', '#163563', '#1f4a7d'], wx, wy, ww, wh);
  for (var i = 0; i < 14; i++) {
    o.set(wx + r() * ww, wy + r() * 18, hex('#cfe8ff'));
  }
  for (var x = wx; x < wx + ww;) {
    final bw = 4 + (r() * 7).floor(), bh = 8 + (r() * 20).floor();
    o.rect(x, wy + wh - bh, bw, bh, '#0b1a33');
    for (var k = 0; k < 4; k++) {
      if (r() < .5) {
        o.set(
          x + 1 + r() * (bw - 2),
          wy + wh - bh + 2 + r() * (bh - 3),
          hex('#ffd98a'),
        );
      }
    }
    x += bw + 1;
  }
  o.rect(wx - 3, wy - 3, ww + 6, 3, '#4a3324');
  o.rect(wx - 3, wy + wh, ww + 6, 4, '#5a3d2a');
  o.rect(wx - 3, wy, 3, wh, '#4a3324');
  o.rect(wx + ww, wy, 3, wh, '#4a3324');
  o.rect(wx + ww / 2 - 1, wy, 2, wh, '#4a3324');
  o.rect(wx, wy + wh / 2 - 1, ww, 2, '#4a3324');
  o.rect(wx - 3, wy + wh + 3, ww + 6, 1, '#2a1d15');
  for (var y = wy - 4; y < wy + wh + 6; y++) {
    final c = y % 4 < 2 ? '#6a2f45' : '#5a2539';
    o.rect(wx - 10, y, 7, 1, c);
    o.rect(wx + ww + 3, y, 7, 1, c);
  }
  o.rect(wx - 12, wy - 6, ww + 24, 2, '#2a1d15');
  // shelf with books
  o.rect(10, 30, 46, 3, '#5a3d2a');
  o.rect(10, 33, 46, 1, '#2a1d15');
  var bx = 12;
  for (final (c, bwid, bht) in [
    ('#c8565f', 4, 12),
    ('#3f7fb5', 3, 10),
    ('#e0b04a', 5, 13),
    ('#5fd3a5', 3, 11),
    ('#b9a7e8', 4, 12),
  ]) {
    o.rect(bx, 30 - bht, bwid, bht, c);
    o.rect(bx, 30 - bht, 1, bht, '#141022');
    bx += bwid + 1;
  }
  if (opt.plant) o.sprite(Sprites.plant, 42, 21);
  // desk (+ lamp if bought)
  o.rect(4, 52, 40, 4, '#5a3d2a');
  o.rect(6, 56, 3, 16, '#3a281c');
  o.rect(39, 56, 3, 16, '#3a281c');
  if (opt.lamp) {
    o.sprite(Sprites.lamp, 16, 43);
    o.glow(21, 46, 40, '#ffd27a', .55);
  }
  o.rect(26, 48, 10, 4, '#e6e0f0');
  o.rect(27, 49, 8, 1, '#8b84a8');
  // floor + rug
  o.gradient(['#3a2a20', '#2f2219'], 0, 72, w, 24);
  for (var y = 74; y < h; y += 5) {
    o.rect(0, y, w, 1, '#271c15');
  }
  for (var y = -8; y <= 8; y++) {
    for (var x = -40; x <= 40; x++) {
      final d = x * x / 1600 + y * y / 64;
      if (d <= 1) {
        o.set(
          80 + x,
          84 + y,
          hex(d > .75 ? '#7a3a4a' : (d > .5 ? '#8f4a58' : '#6a2f40')),
        );
      }
    }
  }
  o.glow(118, 30, 44, '#5aa0d8', .18);
  if (opt.bowl) {
    o.rect(100, 80, 12, 4, '#c8565f');
    o.rect(101, 79, 10, 1, '#ff8a80');
    o.sprite(Sprites.apple, 102, 71);
  }
  if (opt.feast) {
    o.sprite(Sprites.apple, 48, 74);
    o.sprite(Sprites.apple, 56, 76);
    o.sprite(Sprites.cookie, 104, 75);
    for (final (sx, sy) in [(62, 52), (94, 56), (70, 46), (88, 44)]) {
      for (final (dx, dy) in [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)]) {
        o.set(sx + dx, sy + dy, hex('#ffe066'));
      }
    }
  }
  o.glow(roomAnchor.x, roomAnchor.y - 4, 20, '#ffb347', .18);
  return o;
}

/// Time of day for the countdown scene.
enum DayPhase { dawn, day, dusk, night }

DayPhase phaseFor(DateTime t) {
  final h = t.hour;
  if (h >= 5 && h < 9) return DayPhase.dawn;
  if (h >= 9 && h < 16) return DayPhase.day;
  if (h >= 16 && h < 20) return DayPhase.dusk;
  return DayPhase.night;
}

class _SkyTheme {
  const _SkyTheme(
    this.sky,
    this.clouds,
    this.far,
    this.near,
    this.ground,
    this.windows,
    this.sun,
    this.stars,
  );
  final List<String> sky;
  final List<String> clouds;
  final String far;
  final String near;
  final String ground;
  final String windows;
  final String? sun; // null = moon
  final String stars;
}

const _skies = {
  DayPhase.dawn: _SkyTheme(
    [
      '#2a0b35',
      '#5a1449',
      '#8f1f55',
      '#c8325a',
      '#ec5c50',
      '#ff9a6a',
      '#ffc98a',
    ],
    ['#8f1f55', '#c43d66', '#ef6d72', '#ffa38a'],
    '#6a1a48',
    '#40102f',
    '#24081f',
    '#ffb35c',
    '#ffe2a0',
    '#f7c6d9',
  ),
  DayPhase.day: _SkyTheme(
    [
      '#1d4f8f',
      '#2a6db3',
      '#3f8ccc',
      '#62a9db',
      '#8cc5e6',
      '#b7dcef',
      '#d8ecf3',
    ],
    ['#9fc6e4', '#c4dcef', '#e3eef7', '#ffffff'],
    '#4a6f9a',
    '#2c4566',
    '#1b2c44',
    '#ffe9a8',
    '#fff6d8',
    '#d8ecf3',
  ),
  DayPhase.dusk: _SkyTheme(
    [
      '#14163a',
      '#2b2059',
      '#5a2b72',
      '#8f3a77',
      '#c95a6e',
      '#ee8a62',
      '#f9b66e',
    ],
    ['#4a2a6a', '#7a3a78', '#b8577a', '#ec8f78'],
    '#3c2253',
    '#24163a',
    '#150c24',
    '#ffc47a',
    '#ffd9a0',
    '#e8c7e6',
  ),
  DayPhase.night: _SkyTheme(
    [
      '#050914',
      '#0a1328',
      '#0f1d3c',
      '#14284f',
      '#1b3563',
      '#22426f',
      '#2b4f7c',
    ],
    ['#14284f', '#1d3866', '#2a4a7a', '#3a5e8e'],
    '#121f3a',
    '#0b1426',
    '#070d1a',
    '#ffd98a',
    '#e9eef8',
    '#cfe8ff',
  ),
};

const streetSize = (144, 304);
const streetAnchor = SceneAnchor(72, 234);

/// Full-screen street at a given time of day: sky, clouds, sun or moon,
/// two rows of buildings with lit windows, wires and a pavement.
PixelCanvas drawStreet(DayPhase phase) {
  final (w, h) = streetSize;
  final t = _skies[phase]!;
  final o = PixelCanvas(w, h);
  final r = seededRandom(11);
  o.gradient(t.sky, 0, 0, w, 220);
  for (var i = 0; i < (phase == DayPhase.night ? 40 : 18); i++) {
    o.set(r() * w, r() * (phase == DayPhase.night ? 120 : 60), hex(t.stars));
  }
  o.clouds(
    4,
    0,
    30,
    w,
    120,
    t.clouds,
    phase == DayPhase.night ? .66 : .58,
    26,
    9,
  );
  const sx = 98, sy = 176;
  final orb = t.sun ?? '#e9eef8';
  final orbY = phase == DayPhase.day
      ? 140
      : (phase == DayPhase.night ? 150 : sy);
  final rad = phase == DayPhase.night ? 9 : 13;
  for (var y = -rad; y <= rad; y++) {
    for (var x = -rad; x <= rad; x++) {
      if (x * x + y * y <= rad * rad) {
        o.set(sx + x, orbY + y, hex(y < -4 ? '#fffaf0' : orb));
      }
    }
  }
  o.glow(sx, orbY, 60, orb, phase == DayPhase.night ? .25 : .55);
  final litChance = phase == DayPhase.day ? .15 : .55;
  var y = 188;
  for (var x = 0; x < w;) {
    final bw = 8 + (r() * 16).floor(), bh = 6 + (r() * 22).floor();
    o.rect(x, y - bh, bw, 60 + bh, t.far);
    for (var k = 0; k < 3; k++) {
      if (r() < litChance) {
        o.set(x + 2 + r() * (bw - 4), y - bh + 4 + r() * bh, hex(t.windows));
      }
    }
    x += bw;
  }
  y = 214;
  for (var x = -4; x < w;) {
    final bw = 14 + (r() * 20).floor(), bh = 4 + (r() * 16).floor();
    o.rect(x, y - bh, bw, 100, t.near);
    for (var k = 0; k < bw / 2; k++) {
      o.rect(x + k, (y - bh - k * .5).floor(), bw - 2 * k, 1, t.near);
    }
    for (var k = 0; k < 4; k++) {
      if (r() < litChance) {
        final lx = (x + 2 + r() * (bw - 5)).floor(),
            ly = (y - bh + 3 + r() * 14).floor();
        o.rect(lx, ly, 2, 2, t.windows);
        o.glow(lx + 1, ly + 1, 6, t.windows, .35);
      }
    }
    x += bw;
  }
  for (final (px, py) in [(18, 110), (126, 122)]) {
    o.rect(px, py, 2, 130, t.ground);
    o.rect(px - 6, py + 4, 14, 1, t.ground);
  }
  o.line(19, 114, 126, 126, 9, t.ground);
  o.line(19, 119, 126, 131, 8, t.ground);
  o.rect(0, 232, w, 72, t.ground);
  o.rect(0, 232, w, 1, t.windows);
  for (var x = 0; x < w; x += 12) {
    o.rect(x, 236, 1, 68, t.near);
  }
  o.glow(streetAnchor.x, streetAnchor.y - 8, 16, '#ffb36b', .35);
  return o;
}

/// Sprite for the companion at an evolution stage (0..4).
Sprite companionSprite(int stage, {bool hop = false}) => switch (stage) {
  0 => Sprites.egg,
  1 => Sprites.baby,
  2 => hop ? Sprites.tikoHop : Sprites.tiko,
  _ => Sprites.tikoAdult,
};

double clamp01(double v) => math.max(0, math.min(1, v));
