import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/format.dart';
import '../models/run_session.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/dialogs.dart';
import '../widgets/pixel_sprite.dart';
import '../widgets/pixel_ui.dart';
import 'arrival_screen.dart';

/// Screen 3 from the mockups: each block is a stage of the game.
class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const CountdownScreen()));

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  late final Timer _ticker;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _leaveWhenDone(RunSession? s) {
    if (_leaving || (s != null && !s.finished)) return;
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (s == null) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ArrivalScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.session;
    _leaveWhenDone(s);
    if (s == null || s.finished) return const Scaffold();

    final now = app.now();
    final remaining = s.remaining(now);
    final over = remaining.isNegative;
    final behind = s.minutesBehind(now);
    final lifeLeft = remaining.inSeconds / (s.allowedMinutes * 60);
    final next = s.next;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askAbort(app);
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Przerwij grę',
                    onPressed: () => _askAbort(app),
                    icon: const Icon(Icons.close, color: Palette.lavender),
                  ),
                  Text(
                    'ETAP ${s.index + 1}/${s.steps.length}',
                    style: const TextStyle(
                      fontFamily: Fonts.logo,
                      fontSize: 11,
                      color: Palette.lavender,
                    ),
                  ),
                  const Spacer(),
                  _StatusChip(behind: behind),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: PixelSprite(Sprites.forIcon(s.current.icon), scale: 5),
              ),
              const SizedBox(height: 16),
              Text(
                s.current.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: Fonts.logo, fontSize: 18),
              ),
              Text(
                countdownLabel(remaining),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Fonts.numbers,
                  fontSize: 110,
                  height: 1.05,
                  color: over ? Palette.tomato : Palette.paper,
                ),
              ),
              Text(
                over
                    ? 'ponad plan ${s.allowedMinutes} min'
                    : 'zostało z ${s.allowedMinutes} min',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Palette.lavender),
              ),
              const SizedBox(height: 16),
              LifeBar(fraction: lifeLeft),
              const SizedBox(height: 20),
              _Track(
                planned: s.plannedProgress(now),
                actual: s.actualProgress(now),
                runFrame: now.second.isOdd,
                arriveAt: s.arriveAt,
              ),
              const SizedBox(height: 12),
              Text(
                behind > 0
                    ? 'Tiko jest $behind min za planem. Na miejscu ok. ${hhmm(s.projectedArrival(now))}.'
                    : 'Masz ${-behind} min zapasu. Na miejscu ok. ${hhmm(s.projectedArrival(now))}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: behind > 0 ? Palette.amber : Palette.lavender,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PixelButton(
                      label: 'GOTOWE',
                      expand: true,
                      onPressed: app.completeStep,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PixelButton(
                      label: '+5 MIN',
                      fontSize: 12,
                      expand: true,
                      color: Palette.amber,
                      onPressed: app.addFiveMinutes,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                next == null
                    ? 'Dalej: meta!'
                    : 'Dalej: ${next.name}, ${next.minutes} min',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Palette.lavender),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _askAbort(AppState app) async {
    if (await confirm(
      context,
      'Przerwać grę? Postęp tej misji przepadnie.',
      yes: 'Przerwij',
    )) {
      app.abortSession();
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.behind});

  final int behind;

  @override
  Widget build(BuildContext context) {
    final late = behind > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: late ? Palette.tomato : Palette.mint,
      child: Text(
        late ? 'SPÓŹNIENIE $behind MIN' : 'NA CZAS',
        style: const TextStyle(
          fontFamily: Fonts.logo,
          fontSize: 9,
          color: Palette.ink,
        ),
      ),
    );
  }
}

/// Track from home to the finish flag. Solid Tiko = you, faded Tiko =
/// where you should be according to the plan.
class _Track extends StatelessWidget {
  const _Track({
    required this.planned,
    required this.actual,
    required this.runFrame,
    required this.arriveAt,
  });

  final double planned;
  final double actual;
  final bool runFrame;
  final DateTime arriveAt;

  @override
  Widget build(BuildContext context) {
    const spriteW = 16 * 2.0;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final usable = c.maxWidth - spriteW - 20;
            return SizedBox(
              height: 40,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 2,
                    child: Container(height: 4, color: Palette.plum),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 4,
                    child: PixelSprite(Sprites.flag, scale: 2),
                  ),
                  Positioned(
                    left: usable * planned,
                    bottom: 6,
                    child: Opacity(
                      opacity: 0.35,
                      child: PixelSprite(Sprites.tiko, scale: 2),
                    ),
                  ),
                  Positioned(
                    left: usable * actual,
                    bottom: 6,
                    child: PixelSprite(
                      runFrame ? Sprites.tikoRun : Sprites.tiko,
                      scale: 2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Row(
          children: [
            const Text(
              'dom',
              style: TextStyle(color: Palette.lavender, fontSize: 12),
            ),
            const Spacer(),
            Text(
              hhmm(arriveAt),
              style: const TextStyle(
                fontFamily: Fonts.numbers,
                fontSize: 20,
                color: Palette.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
