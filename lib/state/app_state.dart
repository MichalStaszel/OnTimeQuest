import 'package:material_ui/material_ui.dart';

import '../data/defaults.dart';
import '../data/local_store.dart';
import '../logic/planner.dart';
import '../models/block.dart';
import '../models/history.dart';
import '../models/plan.dart';
import '../models/run_session.dart';

/// Single app-wide state object. Screens read it with
/// `context.watch<AppState>()` and call its methods to change things;
/// every change is persisted right away.
class AppState extends ChangeNotifier {
  AppState(this._store, {DateTime Function()? clock})
    : now = clock ?? DateTime.now {
    _blocks = _store.loadBlocks() ?? List.of(defaultBlocks);
    _sets = _store.loadSets() ?? List.of(defaultSets);
    _plan = _store.loadPlan() ?? defaultPlan();
    _session = _store.loadSession();
    _stepHistory = _store.loadStepHistory();
    _arrivals = _store.loadArrivals();
  }

  final LocalStore _store;

  /// Injectable clock, handy in tests.
  final DateTime Function() now;

  late List<Block> _blocks;
  late List<BlockSet> _sets;
  late Plan _plan;
  RunSession? _session;
  late List<StepRecord> _stepHistory;
  late List<ArrivalRecord> _arrivals;

  int _idCounter = 0;
  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  List<Block> get blocks => List.unmodifiable(_blocks);
  List<BlockSet> get sets => List.unmodifiable(_sets);
  Plan get plan => _plan;
  RunSession? get session => _session;
  List<ArrivalRecord> get arrivals => List.unmodifiable(_arrivals);

  Block? blockById(String id) {
    for (final b in _blocks) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Blocks of a set, skipping any that were deleted from the library.
  List<Block> blocksOf(BlockSet set) =>
      set.blockIds.map(blockById).whereType<Block>().toList();

  // ---------------------------------------------------------------- blocks

  void saveBlock({
    String? id,
    required String name,
    required int minutes,
    required String icon,
  }) {
    if (id == null) {
      _blocks.add(
        Block(id: _newId('b'), name: name, minutes: minutes, icon: icon),
      );
    } else {
      final i = _blocks.indexWhere((b) => b.id == id);
      if (i < 0) return;
      _blocks[i] = _blocks[i].copyWith(
        name: name,
        minutes: minutes,
        icon: icon,
      );
    }
    _store.saveBlocks(_blocks);
    notifyListeners();
  }

  void deleteBlock(String id) {
    _blocks.removeWhere((b) => b.id == id);
    _sets = [
      for (final s in _sets)
        s.copyWith(blockIds: s.blockIds.where((b) => b != id).toList()),
    ];
    _store.saveBlocks(_blocks);
    _store.saveSets(_sets);
    notifyListeners();
  }

  // ------------------------------------------------------------------ sets

  void saveSet({
    String? id,
    required String name,
    required List<String> blockIds,
  }) {
    if (id == null) {
      _sets.add(BlockSet(id: _newId('s'), name: name, blockIds: blockIds));
    } else {
      final i = _sets.indexWhere((s) => s.id == id);
      if (i < 0) return;
      _sets[i] = _sets[i].copyWith(name: name, blockIds: blockIds);
    }
    _store.saveSets(_sets);
    notifyListeners();
  }

  void deleteSet(String id) {
    _sets.removeWhere((s) => s.id == id);
    _store.saveSets(_sets);
    notifyListeners();
  }

  /// Saves the current plan's steps as a new set (only steps that still
  /// exist as library blocks).
  void savePlanAsSet(String name) {
    final ids = _plan.steps
        .map((s) => s.blockId)
        .whereType<String>()
        .where((id) => blockById(id) != null)
        .toList();
    saveSet(name: name, blockIds: ids);
  }

  // ------------------------------------------------------------------ plan

  void _setPlan(Plan p) {
    _plan = p;
    _store.savePlan(p);
    notifyListeners();
  }

  void setPlanTitle(String title) => _setPlan(_plan.copyWith(title: title));

  void setArrival(int hour, int minute) =>
      _setPlan(_plan.copyWith(arriveHour: hour, arriveMinute: minute));

  void addBlockToPlan(Block b) => _setPlan(
    _plan.copyWith(steps: [..._plan.steps, PlanStep.fromBlock(b, _newId('p'))]),
  );

  void loadSetIntoPlan(BlockSet set) => _setPlan(
    _plan.copyWith(
      steps: [
        for (final b in blocksOf(set)) PlanStep.fromBlock(b, _newId('p')),
      ],
    ),
  );

  void removeStep(String stepId) => _setPlan(
    _plan.copyWith(steps: _plan.steps.where((s) => s.id != stepId).toList()),
  );

  void setStepMinutes(String stepId, int minutes) => _setPlan(
    _plan.copyWith(
      steps: [
        for (final s in _plan.steps)
          s.id == stepId ? s.copyWith(minutes: minutes) : s,
      ],
    ),
  );

  /// [newIndex] is the final position (as given by `onReorderItem`).
  void moveStep(int oldIndex, int newIndex) {
    final steps = List.of(_plan.steps);
    steps.insert(newIndex, steps.removeAt(oldIndex));
    _setPlan(_plan.copyWith(steps: steps));
  }

  DateTime get arriveAt =>
      nextOccurrence(_plan.arriveHour, _plan.arriveMinute, now());

  Schedule get schedule =>
      planBackwards(arriveAt: arriveAt, steps: _plan.steps);

  // -------------------------------------------------------------- learning

  /// "Your shower usually takes 32 min, not 25" for a plan step, or null.
  int? suggestionFor(PlanStep step) {
    final id = step.blockId;
    if (id == null) return null;
    final samples = [
      for (final r in _stepHistory)
        if (r.blockId == id) r.actualSeconds,
    ];
    return suggestedMinutes(samples, plannedMinutes: step.minutes);
  }

  /// Accept a suggestion: update today's step and the library block.
  void applySuggestion(PlanStep step, int minutes) {
    setStepMinutes(step.id, minutes);
    final b = step.blockId == null ? null : blockById(step.blockId!);
    if (b != null) {
      saveBlock(id: b.id, name: b.name, minutes: minutes, icon: b.icon);
    }
  }

  // ----------------------------------------------------------- the "game"

  void startSession() {
    if (_plan.steps.isEmpty) return;
    _session = RunSession(
      title: _plan.title,
      arriveAt: arriveAt,
      steps: List.of(_plan.steps),
      index: 0,
      stepStartedAt: now(),
    );
    _store.saveSession(_session);
    notifyListeners();
  }

  /// "Gotowe": record how long the step really took and move on.
  void completeStep() {
    final s = _session;
    if (s == null || s.finished) return;
    final t = now();
    _stepHistory.add(
      StepRecord(
        blockId: s.current.blockId,
        name: s.current.name,
        plannedMinutes: s.current.minutes,
        actualSeconds: t.difference(s.stepStartedAt).inSeconds,
        finishedAt: t,
      ),
    );
    _store.saveStepHistory(_stepHistory);
    _session = s.copyWith(
      index: s.index + 1,
      stepStartedAt: t,
      extraMinutes: 0,
    );
    _store.saveSession(_session);
    notifyListeners();
  }

  /// "+5 min" on the current step.
  void addFiveMinutes() {
    final s = _session;
    if (s == null || s.finished) return;
    _session = s.copyWith(extraMinutes: s.extraMinutes + 5, usedPlusFive: true);
    _store.saveSession(_session);
    notifyListeners();
  }

  void abortSession() {
    _session = null;
    _store.saveSession(null);
    notifyListeners();
  }

  /// Answer to "Na czas?". Returns the stored record (with points).
  ArrivalRecord reportArrival({required bool onTime}) {
    final s = _session;
    final arriveAt = s?.arriveAt ?? now();
    final usedPlusFive = s?.usedPlusFive ?? false;
    final streakAfter = currentStreak([
      for (final a in _arrivals) (day: a.arriveAt, onTime: a.onTime),
      (day: arriveAt, onTime: onTime),
    ]);
    final record = ArrivalRecord(
      title: s?.title ?? _plan.title,
      arriveAt: arriveAt,
      onTime: onTime,
      usedPlusFive: usedPlusFive,
      points: pointsFor(
        onTime: onTime,
        usedPlusFive: usedPlusFive,
        streak: streakAfter,
      ),
    );
    _arrivals.add(record);
    _store.saveArrivals(_arrivals);
    _session = null;
    _store.saveSession(null);
    notifyListeners();
    return record;
  }

  int get totalPoints => _arrivals.fold(0, (a, r) => a + r.points);

  int get streak => currentStreak([
    for (final a in _arrivals) (day: a.arriveAt, onTime: a.onTime),
  ]);

  int get bestStreak {
    var best = 0;
    for (var i = 0; i < _arrivals.length; i++) {
      final s = currentStreak([
        for (final a in _arrivals.take(i + 1))
          (day: a.arriveAt, onTime: a.onTime),
      ]);
      if (s > best) best = s;
    }
    return best;
  }
}
