import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../art/sprites.dart';
import '../logic/format.dart';
import '../models/companion.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/ui.dart';
import 'home_shell.dart';
import 'today_screen.dart';

/// Screen 06: arrival. The clock decides "on time" (the last block is the
/// trip), and "Spóźniłem się" is always one tap away: honesty earns points too.
class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  bool? _onTime;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.session;
    if (s == null || _saved) return const Scaffold();
    final onTime = _onTime ??= app.sessionOnTimeByClock;
    final reward = app.previewReward(onTime: onTime);
    final arrived = s.finishedAt ?? app.now();
    final lateBy = (arrived.difference(s.arriveAt).inSeconds / 60).ceil();
    final sp = app.species;
    final count = app.onTimeCount + (onTime ? 1 : 0);
    final next = nextUnlock(sp, count);
    final fresh = unlockedBetween(sp, app.onTimeCount, count);
    final prevMark = [
      0,
      for (final p in perks) p.onTimeNeeded,
      for (final s in sp.stages) s.onTimeNeeded,
    ].where((m) => m <= count).reduce((a, b) => a > b ? a : b);
    final minimal = app.minimal;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            Text(
              '${s.title} · ${hhmm(s.arriveAt)}',
              textAlign: TextAlign.center,
              style: ts(size: 13, color: Palette.muted),
            ),
            const SizedBox(height: 2),
            Text(
              onTime
                  ? 'Jesteś na miejscu ${hhmm(arrived)}'
                  : (lateBy > 0
                        ? 'Spóźnienie $lateBy min. Bywa.'
                        : 'Spóźnienie. Dzięki, że mówisz.'),
              textAlign: TextAlign.center,
              style: ts(size: 22, weight: 600),
            ),
            const SizedBox(height: 12),
            if (fresh.isNotEmpty && !minimal) ...[
              AppCard(
                borderColor: Palette.gold,
                child: Row(
                  children: [
                    const SpriteBox(Sprites.flag, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nowość: ${fresh.join(', ')}! Zobacz, jak teraz wygląda ${sp.name}.',
                        style: ts(size: 14, weight: 600, color: Palette.gold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (!minimal) ...[
              CompanionRoom(
                look: app.lookFor(count),
                feast: onTime,
                bubble: onTime
                    ? null
                    : 'Nic się nie stało. Jutro spróbujemy razem.',
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zdobyte punkty',
                                style: ts(size: 15, weight: 600),
                              ),
                              Text(
                                'wydaj je w zakładce ${sp.name}',
                                style: ts(size: 12, color: Palette.muted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${reward.total}',
                          style: numStyle(46, color: Palette.gold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final l in reward.lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.label,
                                style: ts(size: 13, color: Palette.muted),
                              ),
                            ),
                            Text('+${l.points}', style: numStyle(20)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (reward.apples + reward.cookies > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < reward.apples.clamp(0, 6); i++)
                      const SpriteBox(Sprites.apple, size: 20),
                    for (var i = 0; i < reward.cookies; i++)
                      const SpriteBox(Sprites.cookie, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _foodLine(sp.name, reward.apples, reward.cookies),
                        style: ts(size: 12.5, color: Palette.muted),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              if (next != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Następna nagroda: ${next.name}',
                        style: ts(size: 12, color: Palette.muted),
                      ),
                    ),
                    Text(
                      '$count / ${next.needed} na czas',
                      style: ts(size: 12, color: Palette.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ((count - prevMark) / (next.needed - prevMark))
                        .clamp(0.0, 1.0),
                    minHeight: 6,
                    color: Palette.lilac,
                    backgroundColor: Palette.tabs,
                  ),
                ),
              ],
            ],
            if (minimal)
              AppCard(
                child: Row(
                  children: [
                    const SpriteBox(Sprites.flame, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        onTime
                            ? 'Na czas już $count raz${count == 1 ? '' : 'y'}. Tak trzymaj.'
                            : 'Zapisane. Następnym razem plan uwzględni, ile to naprawdę trwa.',
                        style: ts(size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    onTime ? 'Spóźniłem się' : 'Byłem na czas',
                    tone: ButtonTone.outline,
                    size: 14,
                    onPressed: () => setState(() => _onTime = !onTime),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    minimal ? 'Gotowe' : 'Nakarm ${sp.accusative}',
                    size: 14,
                    onPressed: () {
                      setState(() => _saved = true);
                      app.reportArrival(onTime: onTime);
                      if (!minimal) {
                        app.feed();
                        HomeShell.tab.value = HomeShell.companion;
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _foodLine(String name, int apples, int cookies) {
  final parts = <String>[
    if (apples == 1) '1 jabłko',
    if (apples >= 2 && apples <= 4) '$apples jabłka',
    if (apples >= 5) '$apples jabłek',
    if (cookies == 1) 'ciastko',
  ];
  return '$name dostał ${parts.join(' i ')}';
}
