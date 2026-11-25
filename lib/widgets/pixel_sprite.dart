import 'package:material_ui/material_ui.dart';

/// Pixel sprites ported 1:1 from the mockups. Each character is one pixel;
/// '.' is transparent. Later these can be swapped for exported PNGs.
const Map<String, Color> _pal = {
  'k': Color(0xFF1D1A2F),
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
};

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
  static const tiko = [..._tikoTop, '....kk....kk....', '...kkk....kkk...'];
  static const tikoRun = [..._tikoTop, '...kk......kk...', '..kk........kk..'];

  static const cup = [
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
  static const shower = [
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
  static const iron = [
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
  static const bus = [
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
  static const flame = [
    '.......a........',
    '......aa........',
    '......aaa...a...',
    '.....aaaa..aa...',
    '....araaa.aaa...',
    '....arraaaaaa...',
    '...aarrraaarra..',
    '...arrryyrrrra..',
    '..aarryyyyrrraa.',
    '..arryywwyyrraa.',
    '..arryywwwyyrra.',
    '..arryyywwyyrra.',
    '...arryyyyyrra..',
    '....arrrrrrra...',
    '.....aaaaaaa....',
    '................',
  ];
  static const flag = [
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
  static const shirt = [
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

  /// Icons a block can use, keyed by the id stored in [Block.icon].
  static const blockIcons = <String, List<String>>{
    'cup': cup,
    'shower': shower,
    'iron': iron,
    'shirt': shirt,
    'bus': bus,
    'flag': flag,
    'flame': flame,
  };

  static List<String> forIcon(String id) => blockIcons[id] ?? flag;
}

/// Draws a sprite with crisp square pixels.
class PixelSprite extends StatelessWidget {
  const PixelSprite(this.rows, {super.key, this.scale = 2});

  final List<String> rows;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final w = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    return CustomPaint(
      size: Size(w * scale, rows.length * scale),
      painter: _SpritePainter(rows, scale),
    );
  }
}

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.rows, this.scale);

  final List<String> rows;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        final color = _pal[row[x]];
        if (color == null) continue;
        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(x * scale, y * scale, scale, scale),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SpritePainter old) =>
      old.rows != rows || old.scale != scale;
}
