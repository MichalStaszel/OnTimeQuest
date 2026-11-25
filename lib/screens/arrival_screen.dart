import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/format.dart';
import '../models/history.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/pixel_sprite.dart';
import '../widgets/pixel_ui.dart';

/// Screen 5 from the mockups: "Na czas?" -> points and streak.
class ArrivalScreen extends StatefulWidget {
  const ArrivalScreen({super.key});

  @override
  State<ArrivalScreen> createState() => _ArrivalScreenState();
}

class _ArrivalScreenState extends State<ArrivalScreen> {
  ArrivalRecord? _result;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.session;
    final result = _result;
    final title = result?.title ?? s?.title ?? app.plan.title;
    final at = result?.arriveAt ?? s?.arriveAt ?? app.now();

    return PopScope(
      canPop: result != null,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 24),
              Text(
                '${title.toUpperCase()} · ${hhmm(at)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: Fonts.logo,
                  fontSize: 12,
                  color: Palette.lavender,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: PixelSprite(
                  result?.onTime == false ? Sprites.tiko : Sprites.flag,
                  scale: 6,
                ),
              ),
              const SizedBox(height: 24),
              if (result == null) ...[
                const Text(
                  'NA CZAS?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: Fonts.logo,
                    fontSize: 28,
                    color: Palette.amber,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: PixelButton(
                        label: 'TAK',
                        expand: true,
                        onPressed: () => setState(
                          () => _result = app.reportArrival(onTime: true),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PixelButton(
                        label: 'SPÓŹNIENIE',
                        expand: true,
                        fontSize: 11,
                        color: Palette.tomato,
                        onPressed: () => setState(
                          () => _result = app.reportArrival(onTime: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                _Result(
                  record: result,
                  streak: app.streak,
                  best: app.bestStreak,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.record,
    required this.streak,
    required this.best,
  });

  final ArrivalRecord record;
  final int streak;
  final int best;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          record.onTime ? '+${record.points}' : 'Bywa.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: Fonts.numbers,
            fontSize: 72,
            color: record.onTime ? Palette.gold : Palette.lavender,
          ),
        ),
        Text(
          record.onTime ? 'punktów' : 'Seria się przerwała. Jutro nowa szansa.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Palette.lavender),
        ),
        const SizedBox(height: 20),
        if (record.onTime)
          PixelPanel(
            child: Column(
              children: [
                const _Line('Na czas', '+100'),
                if (!record.usedPlusFive)
                  const _Line('Bez użycia +5 min', '+20'),
                if (record.points > (record.usedPlusFive ? 100 : 120))
                  _Line(
                    'Seria $streak dni',
                    '+${record.points - (record.usedPlusFive ? 100 : 120)}',
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        PixelPanel(
          color: Palette.plumDeep,
          child: Row(
            children: [
              PixelSprite(Sprites.flame, scale: 2),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Seria: $streak dni',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              Text(
                'rekord: $best',
                style: const TextStyle(color: Palette.lavender),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        PixelButton(
          label: 'WRÓĆ DO PLANU',
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(
            value,
            style: const TextStyle(
              fontFamily: Fonts.numbers,
              fontSize: 24,
              color: Palette.gold,
            ),
          ),
        ],
      ),
    );
  }
}
