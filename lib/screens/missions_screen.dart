import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/format.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/ui.dart';
import 'blocks_screen.dart';
import 'mission_edit_screen.dart';
import 'today_screen.dart';

/// Plan tab: upcoming missions by day, plus the block and set library.
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final now = app.now();
    final missions = app.missions;
    String? lastDay;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        ScreenTitle(
          'Plan',
          trailing: FilledButton.icon(
            onPressed: () => MissionEditScreen.open(context),
            style: FilledButton.styleFrom(
              backgroundColor: Palette.gold,
              foregroundColor: Palette.onAccent,
              textStyle: ts(size: 14, weight: 600),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nowa misja'),
          ),
        ),
        if (missions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              'Brak misji. Dodaj pierwszą: cel, godzina, na którą musisz być, i bloki, które cię tam doprowadzą.',
              style: ts(size: 14, color: Palette.muted, height: 1.45),
            ),
          ),
        for (final m in missions) ...[
          if (dayLabel(m.day, now) != lastDay)
            SectionLabel(lastDay = dayLabel(m.day, now)),
          MissionTile(
            mission: m,
            onTap: () => MissionEditScreen.open(context, mission: m),
          ),
          const SizedBox(height: 8),
        ],
        const SectionLabel('Biblioteka'),
        Row(
          children: [
            Expanded(
              child: _LibraryTile(
                title: 'Bloki',
                count: app.blocks.length,
                onTap: () => BlocksScreen.open(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LibraryTile(
                title: 'Zestawy',
                count: app.sets.length,
                onTap: () => BlocksScreen.open(context, sets: true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.title,
    required this.count,
    required this.onTap,
  });

  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(child: Text(title, style: ts(size: 15, weight: 600))),
          Text('$count', style: numStyle(26, color: Palette.muted)),
          const Icon(Icons.chevron_right, color: Palette.faint),
        ],
      ),
    );
  }
}
