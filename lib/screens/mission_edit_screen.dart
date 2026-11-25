import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../art/sprites.dart';
import '../logic/format.dart';
import '../logic/planner.dart';
import '../models/block.dart';
import '../models/mission.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/dialogs.dart';
import '../widgets/ui.dart';
import 'blocks_screen.dart';

/// Screen 03: a mission planned backwards from the arrival time.
class MissionEditScreen extends StatefulWidget {
  const MissionEditScreen({super.key, this.mission});

  final Mission? mission;

  static Future<void> open(BuildContext context, {Mission? mission}) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MissionEditScreen(mission: mission)),
      );

  @override
  State<MissionEditScreen> createState() => _MissionEditScreenState();
}

class _MissionEditScreenState extends State<MissionEditScreen> {
  late Mission _m = widget.mission ?? context.read<AppState>().draftMission();
  late final _title = TextEditingController(text: _m.title);

  bool get _isNew => widget.mission == null;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _update(Mission m) => setState(() => _m = m);

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaj cel misji, np. Dentysta')),
      );
      return;
    }
    if (_m.steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dodaj przynajmniej jeden blok')),
      );
      return;
    }
    context.read<AppState>().saveMission(_m.copyWith(title: title));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final now = app.now();
    final schedule = planBackwards(arriveAt: _m.arriveAt, steps: _m.steps);
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final startPassed = schedule.startAt.isBefore(now);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 90,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Anuluj', style: ts(size: 14, color: Palette.muted)),
        ),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Usuń misję',
              icon: const Icon(Icons.delete_outline, color: Palette.muted),
              onPressed: () async {
                if (!await confirm(
                  context,
                  'Usunąć misję „${_m.title}”?',
                  yes: 'Usuń',
                )) {
                  return;
                }
                app.deleteMission(_m.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          TextButton(onPressed: _save, child: const Text('Zapisz')),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          buildDefaultDragHandles: false,
          itemCount: schedule.steps.length,
          onReorderItem: (o, n) {
            final steps = List.of(_m.steps);
            steps.insert(n, steps.removeAt(o));
            _update(_m.copyWith(steps: steps));
          },
          proxyDecorator: (child, _, _) =>
              Material(color: Colors.transparent, child: child),
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isNew ? 'Nowa misja' : 'Misja',
                style: ts(size: 24, weight: 600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                style: ts(size: 16, weight: 500),
                decoration: const InputDecoration(
                  labelText: 'Cel',
                  hintText: 'np. Dentysta, Praca, Siłownia',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'Muszę być',
                      value: Text(
                        hhmm(_m.arriveAt),
                        style: numStyle(30, color: Palette.gold),
                      ),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: _m.arriveHour,
                            minute: _m.arriveMinute,
                          ),
                          helpText: 'MUSZĘ BYĆ O',
                          builder: (ctx, child) => MediaQuery(
                            data: MediaQuery.of(ctx)
                                .copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          ),
                        );
                        if (t != null) {
                          _update(
                            _m.copyWith(
                              arriveHour: t.hour,
                              arriveMinute: t.minute,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Field(
                      label: 'Kiedy',
                      value: Text(
                        dayLabel(_m.day, now),
                        style: ts(size: 16, weight: 600),
                      ),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _m.day.isBefore(today) ? today : _m.day,
                          firstDate: today,
                          lastDate: today.add(const Duration(days: 365)),
                        );
                        if (d != null) {
                          _update(
                            _m.copyWith(day: DateTime(d.year, d.month, d.day)),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  Pill(
                    text: 'dziś',
                    color: _sameDay(_m.day, today)
                        ? Palette.gold
                        : Palette.muted,
                    onTap: () => _update(_m.copyWith(day: today)),
                  ),
                  Pill(
                    text: 'jutro',
                    color: _sameDay(_m.day, tomorrow)
                        ? Palette.gold
                        : Palette.muted,
                    onTap: () => _update(_m.copyWith(day: tomorrow)),
                  ),
                ],
              ),
              SectionLabel(
                'Liczę od końca',
                trailing: Pill(
                  text: 'Użyj zestawu',
                  onTap: () => _pickSet(app),
                ),
              ),
              if (_m.steps.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Dodaj bloki albo użyj zestawu.',
                    style: ts(size: 13, color: Palette.muted),
                  ),
                ),
            ],
          ),
          itemBuilder: (context, i) {
            final s = schedule.steps[i];
            return _StepRow(
              key: ValueKey(s.step.id),
              index: i,
              step: s.step,
              start: s.start,
              suggestion: app.suggestionFor(s.step.blockId, s.step.minutes),
              onMinutes: (m) => _update(
                _m.copyWith(
                  steps: [
                    for (final x in _m.steps)
                      x.id == s.step.id ? x.copyWith(minutes: m) : x,
                  ],
                ),
              ),
              onRemove: () => _update(
                _m.copyWith(
                  steps: _m.steps.where((x) => x.id != s.step.id).toList(),
                ),
              ),
              onAcceptSuggestion: (m) {
                app.applySuggestion(s.step.blockId!, m);
                _update(
                  _m.copyWith(
                    steps: [
                      for (final x in _m.steps)
                        x.blockId == s.step.blockId
                            ? x.copyWith(minutes: m)
                            : x,
                    ],
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${s.step.name}: $m min. +15 punktów za uczciwy czas',
                    ),
                  ),
                );
              },
            );
          },
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => _addBlock(app),
                icon: const Icon(Icons.add, color: Palette.teal),
                label: Text(
                  'dodaj blok',
                  style: ts(size: 14, weight: 500, color: Palette.teal),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: (startPassed ? Palette.rose : Palette.teal).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (startPassed ? Palette.rose : Palette.teal)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            startPassed ? 'Start (już minął)' : 'Start',
                            style: ts(size: 12, color: Palette.muted),
                          ),
                          Text(hhmm(schedule.startAt), style: numStyle(36)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Budzik',
                          style: ts(size: 12, color: Palette.muted),
                        ),
                        Text(
                          hhmm(
                            schedule.startAt.subtract(
                              const Duration(minutes: 10),
                            ),
                          ),
                          style: numStyle(36),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Całość ${durationLabel(schedule.totalMinutes)}. Budzik to na razie tylko podpowiedź, powiadomienia są w planach.',
                style: ts(size: 11.5, color: Palette.faint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickSet(AppState app) async {
    final set = await showModalBottomSheet<BlockSet>(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text('Użyj zestawu', style: ts(size: 17, weight: 600)),
          Text(
            'Zastąpi bloki tej misji.',
            style: ts(size: 12.5, color: Palette.muted),
          ),
          const SizedBox(height: 10),
          for (final s in app.sets) ...[
            AppCard(
              onTap: () => Navigator.pop(ctx, s),
              radius: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: ts(size: 14.5, weight: 600)),
                        Text(
                          app
                              .blocksOf(s)
                              .map((b) => '${b.name} ${b.minutes}')
                              .join(' · '),
                          style: ts(size: 12, color: Palette.muted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    durationLabel(
                      app.blocksOf(s).fold(0, (a, b) => a + b.minutes),
                    ),
                    style: numStyle(22, color: Palette.gold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (app.sets.isEmpty)
            Text('Brak zestawów.', style: ts(size: 13, color: Palette.muted)),
        ],
      ),
    );
    if (set != null) {
      _update(_m.copyWith(steps: app.stepsFromSet(set), setName: set.name));
    }
  }

  Future<void> _addBlock(AppState app) async {
    final b = await pickBlock(context);
    if (b != null) {
      _update(
        _m.copyWith(
          steps: [..._m.steps, PlanStep.fromBlock(b, app.newId('p'))],
        ),
      );
    }
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, required this.onTap});

  final String label;
  final Widget value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ts(size: 11.5, color: Palette.muted)),
          value,
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.index,
    required this.step,
    required this.start,
    required this.suggestion,
    required this.onMinutes,
    required this.onRemove,
    required this.onAcceptSuggestion,
  });

  final int index;
  final PlanStep step;
  final DateTime start;
  final int? suggestion;
  final ValueChanged<int> onMinutes;
  final VoidCallback onRemove;
  final ValueChanged<int> onAcceptSuggestion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Dismissible(
        key: ValueKey('d-${step.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Palette.rose,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete_outline, color: Palette.onAccent),
        ),
        onDismissed: (_) => onRemove(),
        child: AppCard(
          color: Palette.card2,
          borderColor: null,
          radius: 11,
          padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
          onTap: () async {
            final m = await askMinutes(
              context,
              title: step.name,
              initial: step.minutes,
            );
            if (m != null) onMinutes(m);
          },
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Icon(
                    Icons.drag_indicator,
                    size: 18,
                    color: Color(0xFF3A4A6A),
                  ),
                ),
              ),
              SpriteBox(Sprites.forIcon(step.icon), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            step.name,
                            style: ts(size: 14.5, weight: 600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (suggestion != null) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => onAcceptSuggestion(suggestion!),
                            child: Text(
                              'zwykle $suggestion',
                              style: ts(
                                size: 11.5,
                                weight: 500,
                                color: Palette.gold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      hhmm(start),
                      style: numStyle(19, color: Palette.muted),
                    ),
                  ],
                ),
              ),
              Text('${step.minutes}', style: numStyle(26)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing the block library, with "Nowy blok" at the end.
Future<Block?> pickBlock(BuildContext context) async {
  final app = context.read<AppState>();
  final picked = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text('Dodaj blok', style: ts(size: 17, weight: 600)),
          const SizedBox(height: 10),
          for (final b in app.blocks) ...[
            BlockTile(block: b, onTap: () => Navigator.pop(ctx, b)),
            const SizedBox(height: 6),
          ],
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, 'new'),
            icon: const Icon(Icons.add),
            label: const Text('Nowy blok'),
          ),
        ],
      ),
    ),
  );
  if (picked is Block) return picked;
  if (picked == 'new' && context.mounted) return showBlockEditor(context);
  return null;
}
