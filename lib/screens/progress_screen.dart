import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../art/sprites.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/ui.dart';

/// Screen 08: two numbers that matter (on-time share and average lateness,
/// both against the start), weekly trend, last two weeks, learned blocks.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final rate = app.onTimeRate30, rate0 = app.onTimeRateStart;
    final late = app.avgLate30, late0 = app.avgLateStart;
    final weeks = app.weeklyLateMinutes();
    final now = app.now();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const ScreenTitle('Postęp'),
        const SizedBox(height: 12),
        if (app.arrivals.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Tu zobaczysz, jak zmienia się twoja punktualność. Wystarczy pierwsza misja.',
              style: ts(size: 13.5, color: Palette.muted),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _Kpi(
                label: 'Na czas, 30 dni',
                value: rate == null ? '–' : '${(rate * 100).round()}%',
                color: Palette.teal,
                note: rate0 == null
                    ? 'brak danych'
                    : 'na starcie ${(rate0 * 100).round()}%',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Kpi(
                label: 'Średnie spóźnienie',
                value: late == null ? '–' : '${late.round()} min',
                color: Palette.gold,
                note: late0 == null
                    ? 'brak danych'
                    : 'na starcie ${late0.round()} min',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spóźnienie, minuty na tydzień',
                style: ts(size: 14, weight: 600),
              ),
              const SizedBox(height: 22),
              SizedBox(height: 80, child: _Bars(values: weeks)),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (var i = 0; i < weeks.length; i++)
                    Expanded(
                      child: Text(
                        't${_isoWeek(DateTime(now.year, now.month, now.day - 7 * (weeks.length - 1 - i)))}',
                        textAlign: TextAlign.center,
                        style: ts(size: 9.5, color: Palette.faint),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ostatnie 2 tygodnie',
                      style: ts(size: 14, weight: 600),
                    ),
                  ),
                  Text(
                    'seria ${app.streak} · rekord ${app.bestStreak}',
                    style: ts(size: 12, color: Palette.muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final (i, d) in app.lastTwoWeeks().indexed) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: switch (d) {
                              null => Palette.card2,
                              true => Palette.teal,
                              false => Palette.rose.withValues(alpha: 0.55),
                            },
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (app.learned.isNotEmpty) ...[
          const SectionLabel('Bloki, które się nauczyły'),
          for (final l in app.learned) ...[
            AppCard(
              radius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SpriteBox(Sprites.forIcon(l.icon), size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l.name, style: ts(size: 14, weight: 600)),
                  ),
                  Text(
                    '${l.from} min',
                    style: ts(size: 13, color: Palette.muted),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Palette.muted,
                    ),
                  ),
                  Text('${l.to} min', style: ts(size: 13, weight: 600)),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ],
    );
  }
}

int _isoWeek(DateTime d) {
  final thursday = d.add(Duration(days: 4 - d.weekday));
  final jan1 = DateTime(thursday.year, 1, 1);
  return thursday.difference(jan1).inDays ~/ 7 + 1;
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.color,
    required this.note,
  });

  final String label;
  final String value;
  final Color color;
  final String note;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ts(size: 12, color: Palette.muted)),
          Text(value, style: numStyle(40, color: color)),
          Text(note, style: ts(size: 11.5, color: Palette.muted)),
        ],
      ),
    );
  }
}

/// Weekly lateness bars: teal when the week was nearly on time.
class _Bars extends StatelessWidget {
  const _Bars({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final mx = math.max(1, values.fold(0, math.max));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${values[i]}', style: numStyle(15, color: Palette.muted)),
                Container(
                  height: math.max(2, 60 * values[i] / mx).toDouble(),
                  decoration: BoxDecoration(
                    color: values[i] <= 5 ? Palette.teal : Palette.rose,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
