import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'pixel_canvas.dart';
import 'companion_art.dart';
import 'scenes.dart';
import 'sprites.dart';

final _cache = <String, Future<ui.Image>>{};

Future<ui.Image> sceneImage(String key, PixelCanvas Function() draw) {
  return _cache.putIfAbsent(key, () {
    final c = draw();
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      c.rgba,
      c.w,
      c.h,
      ui.PixelFormat.rgba8888,
      done.complete,
    );
    return done.future;
  });
}

/// A pixel scene scaled with nearest-neighbour, with the companion (and an
/// optional hat) drawn on top at [anchor]. The companion hops every second.
class SceneView extends StatefulWidget {
  const SceneView({
    super.key,
    required this.sceneKey,
    required this.draw,
    required this.sceneSize,
    required this.anchor,
    this.look = const CompanionLook(),
    this.zoom = 2,
    this.fit = BoxFit.fitWidth,
    this.animate = true,
  });

  final String sceneKey;
  final PixelCanvas Function() draw;
  final (int, int) sceneSize;
  final SceneAnchor anchor;

  /// The companion to draw; null draws the scene alone.
  final CompanionLook? look;

  /// The companion is drawn this many times bigger than the scene's pixels
  /// so a hat, a scarf or gold rims are easy to see.
  final int zoom;
  final BoxFit fit;
  final bool animate;

  @override
  State<SceneView> createState() => _SceneViewState();
}

const Sprite _sparkle = ['.y.', 'ywy', '.y.'];

// Where sparkles twinkle, as fractions of the companion's box.
const _sparklesA = [(-0.25, 0.15), (1.2, 0.45), (0.15, -0.35)];
const _sparklesB = [(1.1, -0.1), (-0.2, 0.7), (0.85, -0.4)];

/// Soft light: a warm halo around Tiko, a teal neon under the car.
Widget _glow(CompanionLook l, double left, double top, double w, double h) {
  if (l.isCar) {
    return Positioned(
      left: left - w * 0.1,
      top: top + h * 0.75,
      width: w * 1.2,
      height: h * 0.6,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xCC5FD3A5), Color(0x005FD3A5)],
          ),
        ),
      ),
    );
  }
  return Positioned(
    left: left - w * 0.6,
    top: top - h * 0.5,
    width: w * 2.2,
    height: h * 2,
    child: const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0x80FFE066), Color(0x00FFE066)],
        ),
      ),
    ),
  );
}

class _SceneViewState extends State<SceneView> {
  Timer? _timer;
  bool _hop = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _timer = Timer.periodic(
        const Duration(milliseconds: 700),
        (_) => setState(() => _hop = !_hop),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (sw, sh) = widget.sceneSize;
    return LayoutBuilder(
      builder: (context, c) {
        // Scale: whole pixels per scene pixel where possible.
        final byW = c.maxWidth / sw;
        final byH = c.hasBoundedHeight ? c.maxHeight / sh : byW;
        final scale = widget.fit == BoxFit.cover
            ? (byW > byH ? byW : byH)
            : byW;
        final width = sw * scale, height = sh * scale;
        final look = widget.look;
        final tikoHop = look != null && !look.isCar && look.stage == 2;
        final sprite = look == null
            ? const <String>[]
            : composeCompanion(look, hop: _hop);
        final spW = sprite.fold<int>(0, (m, r) => r.length > m ? r.length : m);
        final spH = sprite.length;
        final z = widget.zoom;
        final cs = scale * z; // companion pixel size
        final left = widget.anchor.x * scale - spW / 2 * cs;
        final top =
            widget.anchor.y * scale - (spH + (_hop && !tikoHop ? 1 : 0)) * cs;
        final perks = look?.perks ?? const <String>{};
        final scene = SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: FutureBuilder<ui.Image>(
                  future: sceneImage(widget.sceneKey, widget.draw),
                  builder: (context, snap) => snap.hasData
                      ? RawImage(
                          image: snap.data,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.none,
                        )
                      : const ColoredBox(color: Color(0xFF141D2F)),
                ),
              ),
              if (perks.contains('glow'))
                _glow(look!, left, top, spW * cs, spH * cs),
              if (look != null)
                Positioned(
                  left: left,
                  top: top,
                  child: PixelSprite(sprite, scale: cs),
                ),
              if (perks.contains('sparkles'))
                for (final (dx, dy) in _hop ? _sparklesA : _sparklesB)
                  Positioned(
                    left: left + (spW * dx - 1.5) * cs,
                    top: top + (spH * dy - 1.5) * cs,
                    child: PixelSprite(_sparkle, scale: cs),
                  ),
            ],
          ),
        );
        if (widget.fit == BoxFit.cover) {
          return ClipRect(
            child: OverflowBox(
              maxWidth: width,
              maxHeight: height,
              child: scene,
            ),
          );
        }
        return scene;
      },
    );
  }
}
