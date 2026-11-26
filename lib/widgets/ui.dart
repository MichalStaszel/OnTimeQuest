import 'package:material_ui/material_ui.dart';

import '../art/sprites.dart';
import '../theme/palette.dart';

/// Rounded card with a hairline border, the basic container.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.color = Palette.card,
    this.borderColor = Palette.line,
    this.onTap,
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: borderColor == null
          ? BorderSide.none
          : BorderSide(color: borderColor!),
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

enum ButtonTone { gold, teal, outline }

class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.tone = ButtonTone.gold,
    this.size = 15,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bg = switch (tone) {
      ButtonTone.gold => Palette.gold,
      ButtonTone.teal => Palette.teal,
      ButtonTone.outline => Colors.transparent,
    };
    final fg = tone == ButtonTone.outline ? Palette.text : Palette.onAccent;
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: onPressed == null && tone != ButtonTone.outline
              ? Palette.card2
              : bg,
          foregroundColor: fg,
          disabledForegroundColor: Palette.faint,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: tone == ButtonTone.outline
                ? const BorderSide(color: Palette.line)
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: ts(
            size: size,
            weight: 600,
            color: onPressed == null ? Palette.faint : fg,
          ),
        ),
      ),
    );
  }
}

/// Small pill, e.g. points "1 240" or "na czas".
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.text,
    this.sprite,
    this.color = Palette.muted,
    this.background,
    this.onTap,
  });

  final String text;
  final Sprite? sprite;
  final Color color;
  final Color? background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? color.withValues(alpha: 0.13),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sprite != null) ...[
                PixelSprite(sprite!, scale: 1.5),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  text,
                  style: ts(size: 12.5, weight: 500, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin rounded progress bar with a label above.
class Meter extends StatelessWidget {
  const Meter({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ts(size: 11.5, color: Palette.muted)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 6,
            color: color,
            backgroundColor: Palette.tabs,
          ),
        ),
      ],
    );
  }
}

/// Small uppercase section header ("PÓŹNIEJ DZIŚ").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: ts(
                size: 11.5,
                weight: 600,
                color: Palette.faint,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Screen title with an optional small line above it.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.over, this.trailing});

  final String title;
  final String? over;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (over != null)
                Text(over!, style: ts(size: 12.5, color: Palette.muted)),
              Text(title, style: ts(size: 24, weight: 600, height: 1.2)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Speech bubble drawn over a scene.
class Bubble extends StatelessWidget {
  const Bubble(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xC7080D17),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Text(text, style: ts(size: 12.5)),
    );
  }
}

/// Points formatted like "1 240".
String pts(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}
