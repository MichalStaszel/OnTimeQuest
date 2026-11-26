import 'package:material_ui/material_ui.dart';

/// Pixel sprites from the design page. One character = one pixel,
/// '.' is transparent. Placeholder art drawn in code until the AI-generated
/// set is ready; swap any of these for a PNG later.
const Map<String, Color> spritePalette = {
  'k': Color(0xFF141022),
  'w': Color(0xFFF4EFFF),
  'm': Color(0xFF5FD3A5),
  'M': Color(0xFF2F9C78),
  'a': Color(0xFFFFB347),
  'A': Color(0xFFD9822B),
  'r': Color(0xFFFF5E5B),
  'R': Color(0xFFB8373F),
  's': Color(0xFF7EC8E3),
  'S': Color(0xFF3F7FB5),
  'p': Color(0xFF3B2D5C),
  'l': Color(0xFFB9A7E8),
  'g': Color(0xFF8B84A8),
  'b': Color(0xFF8A5A3C),
  'y': Color(0xFFFFE066),
  'o': Color(0xFFF28A3A),
  'O': Color(0xFFC4622A),
  'c': Color(0xFFD9A066),
  'n': Color(0xFF5B4A3A),
  'G': Color(0xFF2D6B4A),
  'e': Color(0xFF4E9A5C),
};

typedef Sprite = List<String>;

const _tikoTop = [
  '.kk..........kk.',
  'kaak...kk...kaak',
  'kaaak..kk..kaaak',
  '.kkkkkkkkkkkkkk.',
  '..kaaaaaaaaaak..',
  '.kaawwwwwwwwaak.',
  '.kawwwwwwwwwwak.',
  '.kawwkwwwwkwwak.',
  '.kawwkwwwwkwwak.',
  '.kawwwwwwwwwwak.',
  '.kawrwkwwkwrwak.',
  '.kaawwwkkwwwaak.',
  '..kaaaaaaaaaak..',
  '...kkkkkkkkkk...',
];

abstract final class Sprites {
  // ---- companion: Tiko through its stages
  static const Sprite tiko = [
    ..._tikoTop,
    '....kk....kk....',
    '...kkk....kkk...',
  ];
  static const Sprite tikoHop = [
    '................',
    ..._tikoTop,
    '...kk......kk...',
  ];
  static const Sprite tikoAdult = [
    '..kk..........kk..',
    '.kaak...kk...kaak.',
    '.kaaak..kk..kaaak.',
    '..kkkkkkkkkkkkkk..',
    '...kaaaaaaaaaak...',
    '..kaawwwwwwwwaak..',
    '..kawwwwwwwwwwak..',
    '..kawwkwwwwkwwak..',
    '..kawwkwwwwkwwak..',
    '..kawwwwwwwwwwak..',
    '..kawrwkwwkwrwak..',
    '..kaawwwkkwwwaak..',
    '..krrrrrrrrrrrrk..',
    '..kRRRRRRRRRRRRk..',
    '...kaaaaaaaaaakrk.',
    '..kbbk......kbkRk.',
    '..kbbk......kbk...',
    '...kk.kk..kk.kk...',
    '..kkk.......kkk...',
  ];
  static const Sprite baby = [
    '................',
    '....kk....kk....',
    '...kaak..kaak...',
    '....kkkkkkkk....',
    '...kaaaaaaaak...',
    '..kawwwwwwwwak..',
    '..kawkwwwwkwak..',
    '..kawwwkkwwwak..',
    '..kawwwwwwwwak..',
    '...kaaaaaaaak...',
    '....kkkkkkkk....',
    '....kk....kk....',
    '................',
  ];
  static const Sprite egg = [
    '....kkkk....',
    '...kwwwwk...',
    '..kwwwwwwk..',
    '.kwwawwwwwk.',
    '.kwwwwwawwk.',
    'kwwwwwwwwwwk',
    'kwawwwwwwwwk',
    'kwwwwwawwwwk',
    'kwwwwwwwwwak',
    '.kwwwwwwwwk.',
    '.kwwwwwwwwk.',
    '..kwwwwwwk..',
    '...kkkkkk...',
  ];
  static const Sprite fox = [
    '..k..........k..',
    '.kok........kok.',
    '.kook......kook.',
    '.koookkkkkkoook.',
    '.kooooooooooook.',
    'kooooooooooooooo',
    'kookkooooookkook',
    'kookkooooookkook',
    'kwwoooooooooowwk',
    '.kwwwwokkowwwwk.',
    '..kwwwwwwwwwwk..',
    '...kkwwwwwwkk...',
    '....koooooook...',
    '...koowwwwook...',
    '...koowwwwookoo.',
    '....kkk..kkkkk..',
  ];
  // ---- companion: the car (Kaszlak) through its stages, 23x11
  static const Sprite carWreck = [
    '.......kkkkkkkkk.......',
    '......kgggggkggggk.....',
    '.....kgkkgggkgkkgggk...',
    '...kkkkkkkkkkkkkkkkkk..',
    '..kbbAbbbbbbAbbbbbbbbk.',
    '.kbAbbbbbbkbbbAbbbbbbbk',
    'knbbbbbbbbkbbbbbbAbbbnk',
    'knnnnnnnnnnnnnnnnnnnnnk',
    '.kkkkgggkkkkkkkkgggkkk.',
    '...kkgggk......kgwgkk..',
    '...kkkkkk.......kkk....',
  ];
  static const Sprite carRed = [
    '.......kkkkkkkkk.......',
    '......kssssskssssk.....',
    '.....kswkssskswksssk...',
    '...kkkkkkkkkkkkkkkkkk..',
    '..krrrrrrrrrrrrrrrrrrk.',
    '.krrrrrrrrkrrrrrrrrrrrk',
    'kyrrrrrrrrkrrrrrrrrrrrk',
    'krrrrrrrrrrrrrrrrrrrrrk',
    '.kkkkgggkkkkkkkkgggkkk.',
    '...kkgwgk......kgwgkk..',
    '.....kkk........kkk....',
  ];
  static const Sprite carShiny = [
    '.......kkkkkkkkk.......',
    '......kssssskssssk.....',
    '.....kswkssskswksssk...',
    '...kkkkkkkkkkkkkkkkkk..',
    '..kmmmmmmmmmmmmmmmmmmk.',
    '.kmmmmmmmmkmmmmmmmmmmmk',
    'kymmmmmmmmkmmmmmmmmmmrk',
    'kwwMMMMMMMMMMMMMMMMMwwk',
    '.kkkkgggkkkkkkkkgggkkk.',
    '...kkgwgk......kgwgkk..',
    '.....kkk........kkk....',
  ];
  static const Sprite carRace = [
    '.......kkkkkkkkk.......',
    '......kssssskssssk.kkk.',
    '.....kswkssskswkssskkkk',
    '...kkkkkkkkkkkkkkkkkk..',
    '..kssssssssssssssssssk.',
    '.kssssssssksssssssssssk',
    'kysssssssskssssssssssrk',
    'kSSSSSSSSSSSSSSSSSSSSSk',
    '.kkkkgggkkkkkkkkgggkkk.',
    '...kkgwgk......kgwgkk..',
    '.....kkk........kkk....',
  ];
  static const Sprite carGold = [
    '.......kkkkkkkkk.......',
    '......kssssskssssk.....',
    '.....kswkssskswksssk...',
    '...kkkkkkkkkkkkkkkkkk..',
    '..kyyyyyyyyyyyyyyyyyyk.',
    '.kyyyyyyyykyyyyyyyyyyyk',
    'kyyyyyyyyykyyyyyyyyyyok',
    'kaaaaaaaaaaaaaaaaaaaaak',
    '.kkkkgggkkkkkkkkgggkkk.',
    '...kkgwgk......kgwgkk..',
    '.....kkk........kkk....',
  ];

  // ---- onboarding icon
  static const Sprite car = [
    '.....kkkkkkkk.......',
    '....kssskssssk......',
    '...kssskssssssk.....',
    '.kkkkkkkkkkkkkkkkk..',
    'krrrrrrrrrrrrrrrrrk.',
    'kyrrrrrrrrrrrrrrrrrk',
    'krrrrRRRRRRRRRrrrrrk',
    '.kkkgggkkkkkkkgggkk.',
    '..kgwgk.....kgwgk...',
    '...kkk.......kkk....',
  ];

  // ---- block icons (16x16)
  static const Sprite cup = [
    '................',
    '....s..s........',
    '.....s..s.......',
    '....s..s........',
    '..kkkkkkkkkk....',
    '..kwwwwwwwwkkk..',
    '..kwbbbbbbwk.k..',
    '..kwbbbbbbwk.k..',
    '..kwwwwwwwwkkk..',
    '..kwwwwwwwwk....',
    '...kwwwwwwk.....',
    '.kkkkkkkkkkkkk..',
    '..kgggggggggk...',
    '...kkkkkkkkk....',
    '................',
    '................',
  ];
  static const Sprite shower = [
    '................',
    '..kkkkkkk.......',
    '..kgggggk.......',
    '......kgk.......',
    '.....kkkkkk.....',
    '....kggggggk....',
    '....kkkkkkkk....',
    '.....s..s..s....',
    '....s..s..s.....',
    '.....s..s..s....',
    '....s..s..s.....',
    '.....s..s..s....',
    '....s..s..s.....',
    '................',
    '...ssssssssss...',
    '................',
  ];
  static const Sprite iron = [
    '................',
    '................',
    '................',
    '.....kkkkkkk....',
    '....kk.....k....',
    '....k......k....',
    '...kkkkkkkkkkk..',
    '..krrrrrrrrrrk..',
    '.krrrrrrrrrrrk..',
    'krrrrrrwrrrrrk..',
    'kgggggggggggggk.',
    '.kkkkkkkkkkkkkk.',
    '................',
    '..l...l...l.....',
    '.l...l...l......',
    '................',
  ];
  static const Sprite bus = [
    '................',
    '..kkkkkkkkkkkk..',
    '.kmmmmmmmmmmmmk.',
    '.kmsskssksskmmk.',
    '.kmsskssksskmmk.',
    '.kmmmmmmmmmmmmk.',
    '.kmmmmmmmmmmmmk.',
    '.kMMMMMMMMMMMMk.',
    '.kmmmmmmmmmmmyk.',
    '.kkkkkkkkkkkkkk.',
    '...kkk....kkk...',
    '...kgk....kgk...',
    '....k......k....',
    '................',
    '................',
    '................',
  ];
  static const Sprite shirt = [
    '................',
    '....kkk..kkk....',
    '...kssskkssskk..',
    '..kssssllsssssk.',
    '.kssskssssksssk.',
    '.kssk.ssss.ksk..',
    '..kk.kssssk.kk..',
    '.....kssssk.....',
    '.....kssssk.....',
    '.....kssssk.....',
    '.....kSSSSk.....',
    '.....kkkkkk.....',
    '................',
    '................',
    '................',
    '................',
  ];
  static const Sprite glass = [
    '................',
    '....kkkkkkk.....',
    '....kbbbbbk.....',
    '.....kwwwk......',
    '.....kyyyk......',
    '......kyk.......',
    '......kwk.......',
    '.....kwwwk......',
    '.....kyyyk......',
    '....kbbbbbk.....',
    '....kkkkkkk.....',
    '................',
  ];
  static const Sprite dumbbell = [
    '................',
    '................',
    '................',
    '................',
    'kk..........kk..',
    'kgk........kgk..',
    'kgkkkkkkkkkkgk..',
    'kgk........kgk..',
    'kk..........kk..',
    '................',
  ];
  static const Sprite house = [
    '......kk......',
    '.....krrk.....',
    '....krrrrk....',
    '...krrrrrrk...',
    '..krrrrrrrrk..',
    '.krrrrrrrrrrk.',
    'kkkkkkkkkkkkkk',
    '.kwwwwwwwwwwk.',
    '.kwsswwwwsswk.',
    '.kwsswbbwsswk.',
    '.kwwwwbbwwwwk.',
    '.kwwwwbbwwwwk.',
    '.kkkkkkkkkkkk.',
  ];
  static const Sprite flag = [
    '..k.............',
    '..kkkkkkkkkk....',
    '..kmmwwmmwwk....',
    '..kmmwwmmwwk....',
    '..kwwmmwwmmk....',
    '..kwwmmwwmmk....',
    '..kkkkkkkkkk....',
    '..k.............',
    '..k.............',
    '..k.............',
    '..k.............',
    '..k.............',
    '..k.............',
    '.kkk............',
    'kkkkk...........',
    '................',
  ];

  // ---- small things (8x8 and friends)
  static const Sprite flame = [
    '...a....',
    '..aa.a..',
    '..aaaa..',
    '.arraaa.',
    '.aryyra.',
    'arywwyra',
    '.arwwra.',
    '..aaaa..',
  ];
  static const Sprite coin = [
    '..kkkk..',
    '.kyyyyk.',
    'kyywyyyk',
    'kyywyyyk',
    'kyyyyyyk',
    'kyyyyyAk',
    '.kAAAAk.',
    '..kkkk..',
  ];
  static const Sprite apple = [
    '...k....',
    '..kM....',
    '.kkrrkk.',
    'krrrrrwk',
    'krrrrrrk',
    'krrrrrrk',
    '.krrrrk.',
    '..kkkk..',
  ];
  static const Sprite cookie = [
    '..kkkk..',
    '.kccnck.',
    'kcncccck',
    'kccccnck',
    'kcncccck',
    'kcccncck',
    '.kcccck.',
    '..kkkk..',
  ];
  static const Sprite sparkle = [
    '...y...',
    '...y...',
    '..ywy..',
    'yywwwyy',
    '..ywy..',
    '...y...',
    '...y...',
  ];
  static const Sprite hat = [
    '....kkkk....',
    '..kkrrrrkk..',
    '.krrrrrrrrk.',
    'krrrrrrrrrrk',
    'kwwwwwwwwwwk',
    'kkkkkkkkkkkk',
  ];
  static const Sprite plant = [
    '..e...e...',
    '.eGe.eGe..',
    '..eGeGe...',
    '...eGe....',
    '....e.....',
    '..kkkkk...',
    '..kbbbk...',
    '..kbbbk...',
    '...kkk....',
  ];
  static const Sprite lamp = [
    '...kkkk...',
    '..kyyyyk..',
    '.kyyyyyyk.',
    'kkkkkkkkkk',
    '....kk....',
    '....kk....',
    '....kk....',
    '..kkkkkk..',
  ];

  /// Icons a block can use, keyed by the id stored in `Block.icon`.
  static const blockIcons = <String, Sprite>{
    'cup': cup,
    'shower': shower,
    'iron': iron,
    'shirt': shirt,
    'bus': bus,
    'glass': glass,
    'dumbbell': dumbbell,
    'house': house,
    'flag': flag,
  };

  static Sprite forIcon(String id) => blockIcons[id] ?? glass;
}

/// Draws a sprite with crisp square pixels, scaled to fit [size]
/// (or [scale] screen pixels per sprite pixel).
class PixelSprite extends StatelessWidget {
  const PixelSprite(
    this.rows, {
    super.key,
    this.scale = 2,
    this.silhouette = false,
  });

  final Sprite rows;
  final double scale;

  /// Draw as a dark shape (locked evolution stage).
  final bool silhouette;

  @override
  Widget build(BuildContext context) {
    final w = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    return CustomPaint(
      size: Size(w * scale, rows.length * scale),
      painter: _SpritePainter(rows, scale, silhouette),
    );
  }
}

/// A fixed-size slot with the sprite centred and scaled to fit, so icons of
/// different pixel sizes line up in lists.
class SpriteBox extends StatelessWidget {
  const SpriteBox(
    this.rows, {
    super.key,
    this.size = 28,
    this.silhouette = false,
  });

  final Sprite rows;
  final double size;
  final bool silhouette;

  @override
  Widget build(BuildContext context) {
    final w = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    final h = rows.length;
    final scale = (size / (w > h ? w : h)).clamp(1.0, 64.0);
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: PixelSprite(rows, scale: scale, silhouette: silhouette),
      ),
    );
  }
}

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.rows, this.scale, this.silhouette);

  final Sprite rows;
  final double scale;
  final bool silhouette;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        final color = spritePalette[row[x]];
        if (color == null) continue;
        paint.color = silhouette ? const Color(0xFF2A3550) : color;
        canvas.drawRect(
          Rect.fromLTWH(x * scale, y * scale, scale, scale),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SpritePainter old) =>
      old.rows != rows || old.scale != scale || old.silhouette != silhouette;
}
