import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/format.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/pixel_sprite.dart';
import '../widgets/pixel_ui.dart';

/// Simple progress view: points, streak and recent missions.
/// Levels ("Poz. 3 · Punktualny Żółw") are a follow-up.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final recent = app.arrivals.reversed.take(14).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const SectionLabel('Postęp'),
        Row(
          children: [
            Expanded(
              child: PixelPanel(
                child: Column(
                  children: [
                    Text(
                      '${app.totalPoints}',
                      style: const TextStyle(
                        fontFamily: Fonts.numbers,
                        fontSize: 48,
                        color: Palette.gold,
                      ),
                    ),
                    const Text(
                      'punktów',
                      style: TextStyle(color: Palette.lavender),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PixelPanel(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PixelSprite(Sprites.flame, scale: 2),
                        const SizedBox(width: 6),
                        Text(
                          '${app.streak}',
                          style: const TextStyle(
                            fontFamily: Fonts.numbers,
                            fontSize: 48,
                            color: Palette.amber,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'seria (rekord ${app.bestStreak})',
                      style: const TextStyle(color: Palette.lavender),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionLabel('Ostatnie misje'),
        if (recent.isEmpty)
          const Text(
            'Jeszcze nic. Zagraj pierwszą misję w zakładce Plan.',
            style: TextStyle(color: Palette.lavender),
          ),
        for (final r in recent)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 14,
              height: 14,
              color: r.onTime ? Palette.mint : Palette.tomato,
            ),
            title: Text(r.title),
            subtitle: Text(
              '${r.arriveAt.day}.${two(r.arriveAt.month)} · ${hhmm(r.arriveAt)}',
              style: const TextStyle(color: Palette.lavender),
            ),
            trailing: Text(
              r.onTime ? '+${r.points}' : 'spóźnienie',
              style: TextStyle(
                fontFamily: Fonts.numbers,
                fontSize: 22,
                color: r.onTime ? Palette.gold : Palette.tomato,
              ),
            ),
          ),
      ],
    );
  }
}
