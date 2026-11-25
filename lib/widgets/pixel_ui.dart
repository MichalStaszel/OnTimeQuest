import 'package:material_ui/material_ui.dart';

import '../theme/palette.dart';

/// Chunky button with a hard drop shadow that "presses in" on tap.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Palette.mint,
    this.textColor = Palette.ink,
    this.fontSize = 14,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final double fontSize;
  final bool expand;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final offset = _down ? 0.0 : 4.0;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      transform: Matrix4.translationValues(4 - offset, 4 - offset, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: enabled ? widget.color : Palette.plum,
        border: Border.all(color: Palette.black, width: 3),
        boxShadow: [
          BoxShadow(color: Palette.black, offset: Offset(offset, offset)),
        ],
      ),
      child: Text(
        widget.label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: Fonts.logo,
          fontSize: widget.fontSize,
          height: 1.2,
          color: enabled ? widget.textColor : Palette.lavender,
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                widget.onPressed!();
              }
            : null,
        child: widget.expand
            ? SizedBox(width: double.infinity, child: child)
            : child,
      ),
    );
  }
}

/// Plum panel with a black outline, the basic container of every screen.
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.color = Palette.plum,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Palette.black, width: 3),
        boxShadow: const [
          BoxShadow(color: Palette.black, offset: Offset(4, 4)),
        ],
      ),
      child: child,
    );
  }
}

/// Small all-caps section label ("LICZĘ OD KOŃCA").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = Palette.lavender});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontFamily: Fonts.logo, fontSize: 10, color: color),
      ),
    );
  }
}

/// Segmented "life" bar that empties as time passes.
class LifeBar extends StatelessWidget {
  const LifeBar({super.key, required this.fraction, this.segments = 20});

  final double fraction;
  final int segments;

  @override
  Widget build(BuildContext context) {
    final f = fraction.clamp(0.0, 1.0);
    final filled = (f * segments).ceil();
    final color = f > 0.5
        ? Palette.mint
        : f > 0.2
        ? Palette.amber
        : Palette.tomato;
    return Container(
      height: 22,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Palette.black,
        border: Border.all(color: Palette.black, width: 2),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments; i++)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: i < filled ? color : Palette.plumDeep,
              ),
            ),
        ],
      ),
    );
  }
}
