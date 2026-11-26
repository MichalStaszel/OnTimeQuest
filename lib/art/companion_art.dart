import 'scenes.dart';
import 'sprites.dart';

/// Everything that decides how the companion looks right now.
class CompanionLook {
  const CompanionLook({
    this.species = 'tiko',
    this.stage = 2,
    this.hat = false,
    this.perks = const {},
  });

  final String species;
  final int stage;
  final bool hat;

  /// Unlocked perk ids: outfit, sparkles, badge, glow.
  final Set<String> perks;

  bool get isCar => species == 'car';

  /// Cache key for anything drawn from this look.
  String get key =>
      '$species-$stage-${hat ? 'h' : ''}-${(perks.toList()..sort()).join('.')}';
}

/// Draws [top] over [base] with its top-left at (dx, dy). '.' in [top] is
/// transparent. The result grows when [top] sticks out, so a hat above
/// the head makes the sprite taller (it stays anchored at the bottom).
Sprite overlay(Sprite base, Sprite top, int dx, int dy) {
  final baseW = base.fold<int>(0, (m, r) => r.length > m ? r.length : m);
  final topW = top.fold<int>(0, (m, r) => r.length > m ? r.length : m);
  final offX = dx < 0 ? -dx : 0, offY = dy < 0 ? -dy : 0;
  final w = [baseW + offX, dx + offX + topW].reduce((a, b) => a > b ? a : b);
  final h = [
    base.length + offY,
    dy + offY + top.length,
  ].reduce((a, b) => a > b ? a : b);
  final grid = List.generate(h, (_) => List.filled(w, '.'));
  void paint(Sprite sp, int x0, int y0) {
    for (var y = 0; y < sp.length; y++) {
      for (var x = 0; x < sp[y].length; x++) {
        if (sp[y][x] != '.') grid[y0 + y][x0 + x] = sp[y][x];
      }
    }
  }

  paint(base, offX, offY);
  paint(top, dx + offX, dy + offY);
  return [for (final r in grid) r.join()];
}

/// Replaces [from] with [to] in the given rows.
Sprite recolor(Sprite sp, Iterable<int> rows, String from, String to) {
  final set = rows.toSet();
  return [
    for (var y = 0; y < sp.length; y++)
      set.contains(y) ? sp[y].replaceAll(from, to) : sp[y],
  ];
}

int _firstRow(Sprite sp) {
  for (var y = 0; y < sp.length; y++) {
    if (sp[y].contains(RegExp(r'[^.]'))) return y;
  }
  return 0;
}

/// The companion with its unlocked perks and the hat, ready to draw.
Sprite composeCompanion(CompanionLook l, {bool hop = false}) {
  var sp = companionSprite(l.stage, hop: hop, species: l.species);
  final top = _firstRow(sp);

  if (l.isCar) {
    // Racing stripe along the body, gold rims.
    if (l.perks.contains('outfit')) {
      sp = recolor(sp, [5], sp[5][5], 'w');
    }
    if (l.perks.contains('badge')) sp = recolor(sp, [8, 9], 'g', 'y');
  } else {
    // A red scarf under the face (the Wanderer already has one), gold ears.
    if (l.perks.contains('outfit') && (l.stage == 1 || l.stage == 2)) {
      final neck = sp.lastIndexWhere((r) => r.contains('a'));
      sp = recolor(sp, [neck], 'a', 'r');
      sp = overlay(
        sp,
        const ['R', 'R'],
        sp[neck].lastIndexOf('r') - 1,
        neck + 1,
      );
    }
    if (l.perks.contains('badge') && l.stage >= 1) {
      sp = recolor(sp, [top, top + 1, top + 2], 'a', 'y');
    }
  }

  if (l.hat) {
    final row = sp[top];
    final first = row.indexOf(RegExp(r'[^.]'));
    final last = row.lastIndexOf(RegExp(r'[^.]'));
    final center = (first + last + 1) ~/ 2;
    sp = overlay(sp, Sprites.hat, center - 6, top - (l.isCar ? 5 : 3));
  }
  return sp;
}
