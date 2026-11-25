import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../art/scene_view.dart';
import '../art/scenes.dart';
import '../art/sprites.dart';
import '../logic/format.dart';
import '../models/mission.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/sound_sheet.dart';
import '../widgets/ui.dart';
import 'countdown_screen.dart';
import 'home_shell.dart';
import 'mission_edit_screen.dart';

/// Screen 02: the companion's room on top, one main action in the middle,
/// the rest of the day below.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final c = app.companion;
    final now = app.now();
    final next = app.nextMission;
    final running = app.session;
    final greeting = now.hour < 5 || now.hour >= 18
        ? 'Dobry wieczór'
        : 'Dzień dobry';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        ScreenTitle(
          c.userName.isEmpty ? greeting : '$greeting, ${c.userName}',
          over: longDate(now),
          trailing: Row(
            children: [
              Pill(
                text: pts(c.coins),
                sprite: Sprites.coin,
                color: Palette.gold,
              ),
              const SizedBox(width: 6),
              Pill(text: '${app.streak}', sprite: Sprites.flame),
              IconButton(
                tooltip: 'Dźwięki',
                visualDensity: VisualDensity.compact,
                onPressed: () => showSoundSheet(context),
                icon: Icon(
                  app.soundSettings.silent ? Icons.volume_off : Icons.volume_up,
                  color: Palette.muted,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CompanionRoom(
          bubble: running != null
              ? 'Misja w toku: ${running.title}. Wracamy?'
              : next == null
              ? 'Nic dziś nie mamy. Zaplanujemy coś?'
              : '${next.title} o ${hhmm(next.arriveAt)}. Startujemy o ${hhmm(next.startAt)}?',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Meter(
                label: 'Najedzony',
                value: app.fullness,
                color: Palette.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Meter(
                label: 'Humor',
                value: app.mood,
                color: Palette.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Meter(
                label: 'Do ewolucji',
                value: app.evolutionProgress,
                color: Palette.lilac,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (running != null)
          _RunningCard(
            title: running.title,
            onOpen: () => CountdownScreen.open(context),
          )
        else if (next != null)
          _NextCard(mission: next)
        else
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Brak zaplanowanych misji',
                  style: ts(size: 15, weight: 600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Podaj, gdzie i na kiedy musisz być, a policzę, kiedy zacząć.',
                  style: ts(size: 13, color: Palette.muted),
                ),
                const SizedBox(height: 10),
                AppButton(
                  'Nowa misja',
                  onPressed: () => MissionEditScreen.open(context),
                ),
              ],
            ),
          ),
        if (app.laterToday.isNotEmpty) ...[
          const SectionLabel('Później dziś'),
          for (final m in app.laterToday) ...[
            MissionTile(
              mission: m,
              onTap: () => MissionEditScreen.open(context, mission: m),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

/// The room scene with the companion as it is now (stage, hat, room items).
class CompanionRoom extends StatelessWidget {
  const CompanionRoom({super.key, this.bubble, this.feast = false});

  final String? bubble;
  final bool feast;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final c = app.companion;
    final opt = RoomOptions(
      seed: 3,
      plant: c.owned.contains('plant'),
      lamp: c.owned.contains('lamp'),
      bowl: c.foodCount > 0,
      feast: feast,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Palette.line),
        ),
        child: Stack(
          children: [
            SceneView(
              sceneKey: opt.key,
              draw: () => drawRoom(opt),
              sceneSize: roomSize,
              anchor: roomAnchor,
              stage: app.stage,
              hat: app.showsHat,
            ),
            if (bubble != null)
              Positioned(left: 10, top: 10, child: Bubble(bubble!)),
          ],
        ),
      ),
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final now = app.now();
    final early = now.isBefore(
      mission.startAt.subtract(const Duration(minutes: 1)),
    );
    final leave = _leaveAt(mission);
    return AppCard(
      borderColor: Palette.gold.withValues(alpha: 0.4),
      onTap: () => MissionEditScreen.open(context, mission: mission),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.startAt.isAfter(now)
                          ? 'Następne ${relative(mission.startAt, now)} · ${dayLabel(mission.day, now)}'
                          : 'Pora ruszać!',
                      style: ts(
                        size: 12,
                        color: mission.startAt.isAfter(now)
                            ? Palette.muted
                            : Palette.rose,
                      ),
                    ),
                    Text(
                      '${mission.title} · bądź o ${hhmm(mission.arriveAt)}',
                      style: ts(size: 15, weight: 600),
                    ),
                    Text(
                      [
                        'start ${hhmm(mission.startAt)}',
                        blocksWord(mission.steps.length),
                        if (leave != null) 'wyjście ${hhmm(leave)}',
                      ].join(' · '),
                      style: ts(size: 12, color: Palette.muted),
                    ),
                  ],
                ),
              ),
              Text(
                hhmm(mission.startAt),
                style: numStyle(40, color: Palette.gold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppButton(
            early
                ? 'Zacznij teraz · +20 za wcześniejszy start'
                : 'Zacznij teraz',
            size: 14,
            onPressed: mission.steps.isEmpty
                ? null
                : () {
                    app.startSession(mission);
                    CountdownScreen.open(context);
                  },
          ),
        ],
      ),
    );
  }
}

DateTime? _leaveAt(Mission m) {
  var t = m.arriveAt;
  for (final s in m.steps.reversed) {
    t = t.subtract(Duration(minutes: s.minutes));
    if (s.icon == 'bus') return t;
  }
  return null;
}

class _RunningCard extends StatelessWidget {
  const _RunningCard({required this.title, required this.onOpen});

  final String title;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: Palette.teal.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Misja w toku', style: ts(size: 12, color: Palette.teal)),
          Text(title, style: ts(size: 15, weight: 600)),
          const SizedBox(height: 10),
          AppButton(
            'Wróć do odliczania',
            tone: ButtonTone.teal,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

/// A mission row: time, title, details, icon of its first block.
class MissionTile extends StatelessWidget {
  const MissionTile({
    super.key,
    required this.mission,
    this.onTap,
    this.showDay = false,
  });

  final Mission mission;
  final VoidCallback? onTap;
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final now = context.read<AppState>().now();
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      radius: 12,
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hhmm(mission.startAt),
                  style: numStyle(24, color: Palette.gold),
                ),
                if (showDay)
                  Text(
                    dayLabel(mission.day, now),
                    style: ts(size: 11, color: Palette.muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title.isEmpty ? 'Bez nazwy' : mission.title,
                  style: ts(size: 14.5, weight: 600),
                ),
                Text(
                  [
                    'bądź o ${hhmm(mission.arriveAt)}',
                    if (mission.setName != null)
                      'zestaw „${mission.setName}”'
                    else
                      blocksWord(mission.steps.length),
                  ].join(' · '),
                  style: ts(size: 12, color: Palette.muted),
                ),
              ],
            ),
          ),
          if (mission.steps.isNotEmpty)
            SpriteBox(Sprites.forIcon(mission.steps.last.icon), size: 30),
        ],
      ),
    );
  }
}

/// Used by the reward screen's "Nakarm Tiko" button.
void showCompanionTab() => HomeShell.tab.value = HomeShell.companion;
