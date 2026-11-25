import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../art/scene_view.dart';
import '../art/scenes.dart';
import '../art/sprites.dart';
import '../audio/cues.dart';
import '../logic/format.dart';
import '../models/run_session.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/dialogs.dart';
import '../widgets/sound_sheet.dart';
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
  CueTracker? _cues;

  /// Plays the sounds due since the last frame (each fires once).
  void _playCues(AppState app, RunSession s, DateTime now) {
    final cues = _cues ??= CueTracker(
      warnFor: (i) {
        final id = s.steps[i].blockId;
        return id == null || (app.blockById(id)?.warnBeforeEnd ?? true);
      },
    );
    for (final c in cues.update(s, now)) {
      app.sound.play(c, app.soundSettings);
    }
  }

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
    final now = app.now();
    if (s != null) _playCues(app, s, now);
    _leaveWhenDone(s);
    if (s == null || s.finished) return const Scaffold();

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
                        IconButton(
                          tooltip: 'Dźwięki',
                          onPressed: () => showSoundSheet(context),
                          icon: Icon(
                            app.soundSettings.silent
                                ? Icons.volume_off
                                : Icons.volume_up,
                            color: Palette.text,
                          ),
                        ),
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
                    const SizedBox(height: 8),
                    _Glass(
                      child: MissionBar(session: s, now: now),
                    ),
                    const SizedBox(height: 14),
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
                              Shadow(color: Color(0xCC080D17), blurRadius: 14),
                              Shadow(
                                color: Color(0x99080D17),
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                    ),
                    const SizedBox(height: 6),
                    _Glass(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BlockBar(session: s, now: now),
                          if (leave != null && leave.isAfter(now))
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'wyjście z domu o ${hhmm(leave)}',
                                textAlign: TextAlign.center,
                                style: ts(size: 13, color: Palette.gold),
                              ),
                            ),
                        ],
                      ),
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
                                  ? 'Jabłka za ten etap już nie będzie, ale na miejsce wciąż możesz zdążyć.'
                                  : 'Zmieść się w ${s.allowedMinutes} min, zanim pasek się skończy, a Tiko dostanie jabłko.',
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

/// Current block: how much of its time is used. Fills up as time passes and
/// turns rose when the block runs over.
class BlockBar extends StatelessWidget {
  const BlockBar({super.key, required this.session, required this.now});

  final RunSession session;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final total = session.allowedMinutes * 60;
    final elapsed = now
        .difference(session.stepStartedAt)
        .inSeconds
        .clamp(0, 1 << 30);
    final over = elapsed > total;
    final mm = elapsed ~/ 60, ss = elapsed % 60;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total == 0 ? 1 : (elapsed / total).clamp(0.0, 1.0),
            minHeight: 12,
            color: over ? Palette.rose : Palette.teal,
            backgroundColor: const Color(0x99080D17),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                'minęło $mm:${ss.toString().padLeft(2, '0')}',
                overflow: TextOverflow.ellipsis,
                style: ts(size: 12.5, color: const Color(0xE6ECF2FB)),
              ),
            ),
            Flexible(
              child: Text(
                'ten etap: ${session.allowedMinutes} min${session.extraMinutes > 0 ? ' (z +${session.extraMinutes})' : ''}',
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: ts(size: 12.5, color: const Color(0xE6ECF2FB)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Whole mission: one segment per block, width by planned minutes.
/// Done blocks are full, the current one fills up, the rest are empty.
class MissionBar extends StatelessWidget {
  const MissionBar({super.key, required this.session, required this.now});

  final RunSession session;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final steps = session.steps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                flex: steps[i].minutes.clamp(1, 1000),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: i < session.index
                        ? 1
                        : i > session.index
                        ? 0
                        : (now.difference(session.stepStartedAt).inSeconds /
                                  (session.allowedMinutes * 60))
                              .clamp(0.0, 1.0),
                    minHeight: 5,
                    color: Palette.gold,
                    backgroundColor: const Color(0x99080D17),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'cała misja · na miejscu ok. ${hhmm(session.projectedArrival(now))}, cel ${hhmm(session.arriveAt)}',
          style: ts(size: 11.5, color: const Color(0xCCECF2FB)),
        ),
      ],
    );
  }
}
