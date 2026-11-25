import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../art/scene_view.dart';
import '../art/scenes.dart';
import '../art/sprites.dart';
import '../logic/format.dart';
import '../models/run_session.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/dialogs.dart';
import '../widgets/ui.dart';
import 'reward_screen.dart';

/// Screen 05: full-screen scene for the time of day, big clock, a small
/// concrete reward per stage, Gotowe and +5 min.
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
          MaterialPageRoute(builder: (_) => const RewardScreen()),
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
    final leave = s.leaveAt();
    final next = s.next;
    final phase = phaseFor(now);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askAbort(app);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SceneView(
              sceneKey: 'street-${phase.name}',
              draw: () => drawStreet(phase),
              sceneSize: streetSize,
              anchor: streetAnchor,
              stage: app.stage,
              hat: app.showsHat,
              fit: BoxFit.cover,
            ),
            // Soft darkening at the top and bottom so text stays readable.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99080D17),
                    Color(0x00080D17),
                    Color(0x00080D17),
                    Color(0xB3080D17),
                  ],
                  stops: [0, 0.35, 0.6, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Przerwij misję',
                          onPressed: () => _askAbort(app),
                          icon: const Icon(Icons.close, color: Palette.text),
                        ),
                        Pill(
                          text: 'Etap ${s.index + 1} z ${s.steps.length}',
                          color: Palette.text,
                          background: const Color(0x8C080D17),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Pill(
                              text: behind > 0
                                  ? '$behind min za planem'
                                  : 'na czas',
                              color: behind > 0 ? Palette.rose : Palette.teal,
                              background: const Color(0x8C080D17),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.current.name,
                      textAlign: TextAlign.center,
                      style: ts(size: 22, weight: 600),
                    ),
                    Text(
                      countdownLabel(remaining),
                      textAlign: TextAlign.center,
                      style:
                          numStyle(
                            110,
                            color: over ? Palette.rose : Palette.text,
                          ).copyWith(
                            shadows: const [
                              Shadow(color: Color(0x4DFFFFFF), blurRadius: 18),
                            ],
                          ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'kończysz o '),
                          TextSpan(
                            text: hhmm(s.stepEndsAt),
                            style: ts(size: 14, weight: 600),
                          ),
                          if (leave != null && leave.isAfter(now))
                            TextSpan(text: ' · wyjście ${hhmm(leave)}'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: ts(size: 14, color: const Color(0xE6ECF2FB)),
                    ),
                    const Spacer(),
                    _Glass(
                      child: Row(
                        children: [
                          const SpriteBox(Sprites.apple, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              over
                                  ? 'Spokojnie. Każdy etap się liczy, a dojście na czas wciąż jest możliwe.'
                                  : 'Skończ przed ${hhmm(s.stepEndsAt)}, a Tiko dostanie jabłko.',
                              style: ts(size: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            'Gotowe',
                            tone: ButtonTone.teal,
                            onPressed: app.completeStep,
                          ),
                        ),
                        if (s.current.allowPlusFive) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppButton(
                              '+5 min',
                              onPressed: app.addFiveMinutes,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      next == null
                          ? 'To ostatni etap. Potem meta!'
                          : 'Dalej: ${next.name}, ${next.minutes} min',
                      textAlign: TextAlign.center,
                      style: ts(size: 13, color: const Color(0xCCECF2FB)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _askAbort(AppState app) async {
    if (await confirm(
      context,
      'Przerwać misję? Odliczanie się skończy, punkty za nią nie wpadną.',
      yes: 'Przerwij',
    )) {
      app.abortSession();
    }
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x99080D17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: child,
    );
  }
}
