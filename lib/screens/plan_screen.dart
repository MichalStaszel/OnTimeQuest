import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/format.dart';
import '../logic/planner.dart';
import '../models/block.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/dialogs.dart';
import '../widgets/pixel_sprite.dart';
import '../widgets/pixel_ui.dart';
import 'countdown_screen.dart';

/// Screen 1 from the mockups: "I must be there at 12:00" -> start at 09:55.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final schedule = app.schedule;

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      buildDefaultDragHandles: false,
      header: _MissionHeader(schedule: schedule),
      footer: _Footer(schedule: schedule),
      itemCount: schedule.steps.length,
      onReorderItem: app.moveStep,
      itemBuilder: (context, i) {
        final s = schedule.steps[i];
        return _StepTile(key: ValueKey(s.step.id), index: i, scheduled: s);
      },
      proxyDecorator: (child, _, _) =>
          Material(color: Colors.transparent, child: child),
    );
  }
}

class _MissionHeader extends StatelessWidget {
  const _MissionHeader({required this.schedule});

  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final plan = app.plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ONTIME QUEST',
          style: TextStyle(
            fontFamily: Fonts.logo,
            fontSize: 16,
            color: Palette.amber,
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Misja na dziś'),
        PixelPanel(
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final t = await askText(
                      context,
                      title: 'Dokąd?',
                      initial: plan.title,
                    );
                    if (t != null && t.isNotEmpty) app.setPlanTitle(t);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'dotknij, by zmienić',
                        style: TextStyle(fontSize: 12, color: Palette.lavender),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: plan.arriveHour,
                      minute: plan.arriveMinute,
                    ),
                    helpText: 'MUSZĘ BYĆ O',
                    builder: (ctx, child) => MediaQuery(
                      data: MediaQuery.of(ctx)
                          .copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    ),
                  );
                  if (t != null) app.setArrival(t.hour, t.minute);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'muszę być',
                      style: TextStyle(fontSize: 12, color: Palette.lavender),
                    ),
                    Text(
                      hhmm(schedule.arriveAt),
                      style: const TextStyle(
                        fontFamily: Fonts.numbers,
                        fontSize: 40,
                        color: Palette.amber,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionLabel('Liczę od końca'),
        _TimelineEdge(
          time: schedule.startAt,
          label: 'START',
          color: Palette.mint,
        ),
      ],
    );
  }
}

class _TimelineEdge extends StatelessWidget {
  const _TimelineEdge({
    required this.time,
    required this.label,
    required this.color,
  });

  final DateTime time;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              hhmm(time),
              style: TextStyle(
                fontFamily: Fonts.numbers,
                fontSize: 24,
                color: color,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: Fonts.logo,
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({super.key, required this.index, required this.scheduled});

  final int index;
  final ScheduledStep scheduled;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final step = scheduled.step;
    final suggestion = app.suggestionFor(step);
    return Dismissible(
      key: ValueKey('dismiss-${step.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Palette.tomato,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Palette.ink),
      ),
      onDismissed: (_) => app.removeStep(step.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(
                hhmm(scheduled.start),
                style: const TextStyle(
                  fontFamily: Fonts.numbers,
                  fontSize: 24,
                  color: Palette.lavender,
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final m = await askMinutes(
                    context,
                    title: step.name,
                    initial: step.minutes,
                  );
                  if (m != null) app.setStepMinutes(step.id, m);
                },
                child: PixelPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      PixelSprite(Sprites.forIcon(step.icon), scale: 1.75),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          step.name,
                          style: const TextStyle(fontSize: 17),
                        ),
                      ),
                      if (suggestion != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _SuggestionBadge(
                            minutes: suggestion,
                            onTap: () => _askApply(context, app, suggestion),
                          ),
                        ),
                      Text(
                        '${step.minutes}',
                        style: const TextStyle(
                          fontFamily: Fonts.numbers,
                          fontSize: 26,
                          color: Palette.amber,
                        ),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.drag_indicator,
                            color: Palette.lavender,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _askApply(
    BuildContext context,
    AppState app,
    int minutes,
  ) async {
    final step = scheduled.step;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'TIKO ZAUWAŻYŁ',
          style: TextStyle(fontFamily: Fonts.logo, fontSize: 13),
        ),
        content: Text(
          '${step.name} trwa zwykle $minutes min, nie ${step.minutes}. Ustawić $minutes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Zostaw ${step.minutes}'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Ustaw $minutes',
              style: const TextStyle(color: Palette.mint),
            ),
          ),
        ],
      ),
    );
    if (ok == true) app.applySuggestion(step, minutes);
  }
}

class _SuggestionBadge extends StatelessWidget {
  const _SuggestionBadge({required this.minutes, required this.onTap});

  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        color: Palette.amber,
        child: Text(
          '$minutes?',
          style: const TextStyle(
            fontFamily: Fonts.numbers,
            fontSize: 18,
            color: Palette.ink,
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.schedule});

  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final lateBy = app.now().difference(schedule.startAt).inMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (app.plan.steps.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Plan jest pusty. Dodaj blok albo wczytaj zestaw.',
              style: TextStyle(color: Palette.lavender),
            ),
          ),
        _TimelineEdge(
          time: schedule.arriveAt,
          label: 'NA MIEJSCU',
          color: Palette.amber,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: () => _pickBlock(context, app),
              icon: const Icon(Icons.add),
              label: const Text('blok'),
            ),
            TextButton.icon(
              onPressed: () => _pickSet(context, app),
              icon: const Icon(Icons.layers),
              label: const Text('wczytaj zestaw'),
            ),
            TextButton.icon(
              onPressed: app.plan.steps.isEmpty
                  ? null
                  : () async {
                      final name = await askText(
                        context,
                        title: 'Nazwa zestawu',
                      );
                      if (name != null && name.isNotEmpty) {
                        app.savePlanAsSet(name);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Zapisano zestaw „$name”')),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.save),
              label: const Text('zapisz jako zestaw'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PixelPanel(
          color: Palette.plumDeep,
          child: Column(
            children: [
              const Text(
                'zacznij o',
                style: TextStyle(color: Palette.lavender),
              ),
              Text(
                hhmm(schedule.startAt),
                style: TextStyle(
                  fontFamily: Fonts.numbers,
                  fontSize: 72,
                  height: 1,
                  color: lateBy > 0 ? Palette.tomato : Palette.mint,
                ),
              ),
              Text(
                lateBy > 0
                    ? 'Już ${durationLabel(lateBy)} po starcie. Ruszaj teraz!'
                    : 'Całość: ${durationLabel(schedule.totalMinutes)}',
                style: TextStyle(
                  fontFamily: Fonts.numbers,
                  fontSize: NumText.size,
                  color: lateBy > 0 ? Palette.tomato : Palette.lavender,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PixelButton(
          label: 'START GRY',
          expand: true,
          fontSize: 16,
          onPressed: app.plan.steps.isEmpty
              ? null
              : () {
                  app.startSession();
                  CountdownScreen.open(context);
                },
        ),
      ],
    );
  }

  Future<void> _pickBlock(BuildContext context, AppState app) async {
    final b = await showModalBottomSheet<Block>(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: SectionLabel('Dodaj blok')),
          for (final b in app.blocks)
            ListTile(
              leading: PixelSprite(Sprites.forIcon(b.icon), scale: 1.5),
              title: Text(b.name),
              trailing: Text(
                '${b.minutes} min',
                style: const TextStyle(
                  fontFamily: Fonts.numbers,
                  fontSize: 22,
                  color: Palette.amber,
                ),
              ),
              onTap: () => Navigator.pop(ctx, b),
            ),
        ],
      ),
    );
    if (b != null) app.addBlockToPlan(b);
  }

  Future<void> _pickSet(BuildContext context, AppState app) async {
    final s = await showModalBottomSheet<BlockSet>(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: SectionLabel('Wczytaj zestaw (zastąpi plan)')),
          for (final s in app.sets)
            ListTile(
              title: Text(s.name),
              subtitle: Text(
                app.blocksOf(s).map((b) => b.name).join(' · '),
                style: const TextStyle(color: Palette.lavender),
              ),
              trailing: Text(
                durationLabel(app.blocksOf(s).fold(0, (a, b) => a + b.minutes)),
                style: const TextStyle(
                  fontFamily: Fonts.numbers,
                  fontSize: 22,
                  color: Palette.amber,
                ),
              ),
              onTap: () => Navigator.pop(ctx, s),
            ),
          if (app.sets.isEmpty)
            const ListTile(
              title: Text('Brak zestawów. Utwórz je w zakładce Bloki.'),
            ),
        ],
      ),
    );
    if (s != null) app.loadSetIntoPlan(s);
  }
}
