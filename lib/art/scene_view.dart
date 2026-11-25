import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'pixel_canvas.dart';
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
    this.stage = 2,
    this.hat = false,
    this.fit = BoxFit.fitWidth,
    this.animate = true,
  });

  final String sceneKey;
  final PixelCanvas Function() draw;
  final (int, int) sceneSize;
  final SceneAnchor anchor;
  final int stage;
  final bool hat;
  final BoxFit fit;
  final bool animate;

  @override
  State<SceneView> createState() => _SceneViewState();
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
        final sprite = companionSprite(widget.stage, hop: _hop);
        final spW = sprite.fold<int>(0, (m, r) => r.length > m ? r.length : m);
        final spH = sprite.length;
        final left = (widget.anchor.x - spW / 2) * scale;
        final top =
            (widget.anchor.y - spH - (_hop && widget.stage != 2 ? 1 : 0)) *
            scale;
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
              Positioned(
                left: left,
                top: top,
                child: PixelSprite(sprite, scale: scale),
              ),
              if (widget.hat && widget.stage >= 2)
                Positioned(
                  left: left + (widget.stage == 2 ? 2 : 3) * scale,
                  top: top + ((_hop && widget.stage == 2 ? 1 : 0) - 3) * scale,
                  child: PixelSprite(Sprites.hat, scale: scale),
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
