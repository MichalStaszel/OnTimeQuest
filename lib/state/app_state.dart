import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../audio/sound_player.dart';
import '../audio/sound_settings.dart';
import '../data/defaults.dart';
import '../data/local_store.dart';
import '../logic/planner.dart';
import '../logic/rewards.dart';
import '../models/block.dart';
import '../models/companion.dart';
import '../models/history.dart';
import '../models/mission.dart';
import '../models/run_session.dart';

/// Single app-wide state object. Screens read it with
/// `context.watch<AppState>()` and call its methods to change things;
/// every change is persisted right away.
class AppState extends ChangeNotifier {
  AppState(this._store, {DateTime Function()? clock, SoundPlayer? sound})
    : now = clock ?? DateTime.now,
      sound = sound ?? SoundPlayer() {
    _soundSettings = _store.loadSound();
    _blocks = _store.loadBlocks() ?? List.of(defaultBlocks);
    _sets = _store.loadSets() ?? List.of(defaultSets);
    _missions = _store.loadMissions() ?? [sampleMission(now())];
    _session = _store.loadSession();
    _stepHistory = _store.loadStepHistory();
    _arrivals = _store.loadArrivals();
    _learned = _store.loadLearned();
    _companion = _store.loadCompanion();
  }

  final LocalStore _store;

  /// Injectable clock, handy in tests.
  final DateTime Function() now;

  /// Plays countdown cues. Silent unless the app passes a device player.
  final SoundPlayer sound;
  late SoundSettings _soundSettings;
  SoundSettings get soundSettings => _soundSettings;

  void setSoundSettings(SoundSettings v) {
    _soundSettings = v;
    _store.saveSound(v);
    notifyListeners();
  }

  late List<Block> _blocks;
  late List<BlockSet> _sets;
  late List<Mission> _missions;
  RunSession? _session;
  late List<StepRecord> _stepHistory;
  late List<ArrivalRecord> _arrivals;
  late List<LearnedBlock> _learned;
  late CompanionState _companion;

  int _idCounter = 0;
  String newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  List<Block> get blocks => List.unmodifiable(_blocks);
  List<BlockSet> get sets => List.unmodifiable(_sets);
  RunSession? get session => _session;
  List<ArrivalRecord> get arrivals => List.unmodifiable(_arrivals);
  List<LearnedBlock> get learned => List.unmodifiable(_learned);
  CompanionState get companion => _companion;

  Block? blockById(String id) {
    for (final b in _blocks) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Blocks of a set, skipping any that were deleted from the library.
  List<Block> blocksOf(BlockSet set) =>
      set.blockIds.map(blockById).whereType<Block>().toList();

  // ------------------------------------------------------------ onboarding

  void completeOnboarding({required String name, required String companionId}) {
    _setCompanion(
      _companion.copyWith(
        userName: name.trim(),
        companionId: companionId,
        fullnessAt: now(),
      ),
    );
  }

  // ---------------------------------------------------------------- blocks

  Block saveBlock({
    String? id,
    required String name,
    required int minutes,
    required String icon,
    bool warnBeforeEnd = true,
    bool allowPlusFive = true,
  }) {
    final i = id == null ? -1 : _blocks.indexWhere((b) => b.id == id);
    final block = Block(
      id: i < 0 ? newId('b') : id!,
      name: name,
      minutes: minutes,
      icon: icon,
      warnBeforeEnd: warnBeforeEnd,
      allowPlusFive: allowPlusFive,
    );
    if (i < 0) {
      _blocks.add(block);
    } else {
      _blocks[i] = block;
    }
    _store.saveBlocks(_blocks);
    notifyListeners();
    return block;
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
      _sets.add(BlockSet(id: newId('s'), name: name, blockIds: blockIds));
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

  List<PlanStep> stepsFromSet(BlockSet set) => [
    for (final b in blocksOf(set)) PlanStep.fromBlock(b, newId('p')),
  ];

  // -------------------------------------------------------------- missions

  /// Upcoming missions, soonest first (ones still in progress included).
  List<Mission> get missions {
    final list = List.of(_missions)
      ..sort((a, b) => a.arriveAt.compareTo(b.arriveAt));
    return list;
  }

  Mission? missionById(String id) {
    for (final m in _missions) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// The next mission that has not ended yet (arrival time in the future,
  /// or not more than an hour ago).
  Mission? get nextMission {
    final t = now().subtract(const Duration(hours: 1));
    for (final m in missions) {
      if (m.arriveAt.isAfter(t)) return m;
    }
    return null;
  }

  /// Other missions later today, after [nextMission].
  List<Mission> get laterToday {
    final next = nextMission;
    final n = now();
    return [
      for (final m in missions)
        if (m.id != next?.id &&
            m.arriveAt.isAfter(n) &&
            m.day.year == n.year &&
            m.day.month == n.month &&
            m.day.day == n.day)
          m,
    ];
  }

  /// A new, unsaved mission for the editor.
  Mission draftMission() {
    final n = now();
    final tomorrow = DateTime(n.year, n.month, n.day + 1);
    return Mission(
      id: newId('m'),
      title: '',
      day: tomorrow,
      arriveHour: 9,
      arriveMinute: 0,
      steps: const [],
    );
  }

  void saveMission(Mission m) {
    final i = _missions.indexWhere((x) => x.id == m.id);
    if (i < 0) {
      _missions.add(m);
    } else {
      _missions[i] = m;
    }
    _store.saveMissions(_missions);
    notifyListeners();
  }

  void deleteMission(String id) {
    _missions.removeWhere((m) => m.id == id);
    _store.saveMissions(_missions);
    notifyListeners();
  }

  Schedule scheduleOf(Mission m) =>
      planBackwards(arriveAt: m.arriveAt, steps: m.steps);

  // -------------------------------------------------------------- learning

  List<int> _samples(String blockId) => [
    for (final r in _stepHistory)
      if (r.blockId == blockId) r.actualSeconds,
  ];

  /// "Your shower usually takes 32 min, not 25", or null.
  int? suggestionFor(String? blockId, int plannedMinutes) => blockId == null
      ? null
      : suggestedMinutes(_samples(blockId), plannedMinutes: plannedMinutes);

  /// How many times a block was timed, for "Z 7 ostatnich razy...".
  int sampleCount(String blockId) => math.min(7, _samples(blockId).length);

  /// Accept a suggestion: update the block, every upcoming mission that uses
  /// it, and award points for listening to the data.
  void applySuggestion(String blockId, int minutes) {
    final b = blockById(blockId);
    if (b == null) return;
    if (b.minutes != minutes) {
      final from =
          _learned.where((l) => l.blockId == blockId).firstOrNull?.from ??
          b.minutes;
      _learned.removeWhere((l) => l.blockId == blockId);
      _learned.add(LearnedBlock(blockId, b.name, b.icon, from, minutes));
      _store.saveLearned(_learned);
    }
    _missions = [
      for (final m in _missions)
        m.copyWith(
          steps: [
            for (final s in m.steps)
              s.blockId == blockId ? s.copyWith(minutes: minutes) : s,
          ],
        ),
    ];
    _store.saveMissions(_missions);
    _addCoins(Points.acceptSuggestion);
    saveBlock(
      id: b.id,
      name: b.name,
      minutes: minutes,
      icon: b.icon,
      warnBeforeEnd: b.warnBeforeEnd,
      allowPlusFive: b.allowPlusFive,
    );
  }

  // ----------------------------------------------------------- the "game"

  void startSession(Mission m) {
    if (m.steps.isEmpty) return;
    final t = now();
    _session = RunSession(
      missionId: m.id,
      title: m.title,
      arriveAt: m.arriveAt,
      steps: List.of(m.steps),
      index: 0,
      stepStartedAt: t,
      startedEarly: t.isBefore(m.startAt.subtract(const Duration(minutes: 1))),
    );
    _store.saveSession(_session);
    notifyListeners();
  }

  /// "Gotowe": record how long the step really took and move on.
  void completeStep() {
    final s = _session;
    if (s == null || s.finished) return;
    final t = now();
    final actual = t.difference(s.stepStartedAt).inSeconds;
    _stepHistory.add(
      StepRecord(
        blockId: s.current.blockId,
        name: s.current.name,
        plannedMinutes: s.current.minutes,
        actualSeconds: actual,
        finishedAt: t,
      ),
    );
    _store.saveStepHistory(_stepHistory);
    final early = s.current.minutes - (actual / 60).ceil();
    final last = s.index + 1 >= s.steps.length;
    _session = s.copyWith(
      index: s.index + 1,
      stepStartedAt: t,
      extraMinutes: 0,
      earlyBlocks: early >= 1
          ? [...s.earlyBlocks, EarlyBlock(s.current.name, early)]
          : null,
      blocksInTime: actual <= s.allowedMinutes * 60 ? s.blocksInTime + 1 : null,
      finishedAt: last ? t : null,
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

  /// Whether the finished session made it on time, judged by the clock.
  bool get sessionOnTimeByClock {
    final s = _session;
    if (s == null) return false;
    final at = s.finishedAt ?? now();
    return !at.isAfter(s.arriveAt.add(const Duration(seconds: 59)));
  }

  int _streakWith({required DateTime day, required bool onTime}) =>
      currentStreak([
        for (final a in _arrivals) (day: a.arriveAt, onTime: a.onTime),
        (day: day, onTime: onTime),
      ]);

  /// The reward the current session would get, before it is saved.
  Reward previewReward({required bool onTime}) {
    final s = _session!;
    return computeReward(
      onTime: onTime,
      usedPlusFive: s.usedPlusFive,
      startedEarly: s.startedEarly,
      earlyBlocks: s.earlyBlocks,
      blocksInTime: s.blocksInTime,
      streakAfter: _streakWith(day: s.arriveAt, onTime: onTime),
    );
  }

  /// Saves the mission result, pays out points and food, ends the session.
  Reward reportArrival({required bool onTime}) {
    final s = _session!;
    final reward = previewReward(onTime: onTime);
    final arrivedAt = s.finishedAt ?? now();
    final lateBy = (arrivedAt.difference(s.arriveAt).inSeconds / 60).ceil();
    _arrivals.add(
      ArrivalRecord(
        title: s.title,
        arriveAt: s.arriveAt,
        arrivedAt: arrivedAt,
        onTime: onTime,
        usedPlusFive: s.usedPlusFive,
        points: reward.total,
        lateMinutes: onTime ? 0 : math.max(1, lateBy),
      ),
    );
    _store.saveArrivals(_arrivals);
    final food = Map.of(_companion.food);
    food['apple'] = (food['apple'] ?? 0) + reward.apples;
    food['cookie'] = (food['cookie'] ?? 0) + reward.cookies;
    _setCompanion(
      _companion.copyWith(coins: _companion.coins + reward.total, food: food),
      notify: false,
    );
    _missions.removeWhere((m) => m.id == s.missionId);
    _store.saveMissions(_missions);
    _session = null;
    _store.saveSession(null);
    notifyListeners();
    return reward;
  }

  // ------------------------------------------------------------- companion

  void _setCompanion(CompanionState c, {bool notify = true}) {
    _companion = c;
    _store.saveCompanion(c);
    if (notify) notifyListeners();
  }

  void _addCoins(int n) => _setCompanion(
    _companion.copyWith(coins: _companion.coins + n),
    notify: false,
  );

  double get fullness => _companion.fullnessNow(now());

  /// Humour: mostly how fed the companion is, plus a bit for a cosy room
  /// and a running streak. Never drops below a calm 30%.
  double get mood {
    final items = _companion.owned.where((i) => i != 'hat').length;
    return (0.3 + fullness * 0.5 + items * 0.05 + (streak > 0 ? 0.1 : 0)).clamp(
      0.3,
      1.0,
    );
  }

  /// Feeds one piece of food; cookies first (they fill more).
  bool feed() {
    final food = Map.of(_companion.food);
    final id = (food['cookie'] ?? 0) > 0
        ? 'cookie'
        : ((food['apple'] ?? 0) > 0 ? 'apple' : null);
    if (id == null) return false;
    food[id] = food[id]! - 1;
    _setCompanion(
      _companion.copyWith(
        food: food,
        fullness: (fullness + foodValue[id]!).clamp(0.0, 1.0),
        fullnessAt: now(),
      ),
    );
    return true;
  }

  /// Buys a shop item. Returns false if there are not enough points.
  bool buy(ShopItem item) {
    if (_companion.coins < item.price) return false;
    if (item.kind != ItemKind.food && _companion.owned.contains(item.id)) {
      return false;
    }
    var c = _companion.copyWith(coins: _companion.coins - item.price);
    if (item.kind == ItemKind.food) {
      final food = Map.of(c.food);
      food[item.id] = (food[item.id] ?? 0) + item.amount;
      c = c.copyWith(food: food);
    } else {
      c = c.copyWith(owned: {...c.owned, item.id});
    }
    _setCompanion(c);
    return true;
  }

  void toggleHat() =>
      _setCompanion(_companion.copyWith(wearingHat: !_companion.wearingHat));

  bool get showsHat =>
      _companion.owned.contains('hat') && _companion.wearingHat;

  // ----------------------------------------------------------------- stats

  int get onTimeCount => _arrivals.where((a) => a.onTime).length;
  int get stage => stageFor(onTimeCount);

  /// Progress (0..1) towards the next evolution stage.
  double get evolutionProgress {
    final s = stage;
    if (s >= stages.length - 1) return 1;
    final from = stages[s].onTimeNeeded, to = stages[s + 1].onTimeNeeded;
    return ((onTimeCount - from) / (to - from)).clamp(0.0, 1.0);
  }

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
      best = math.max(best, s);
    }
    return best;
  }

  List<ArrivalRecord> _lastDays(int days) {
    final from = now().subtract(Duration(days: days));
    return _arrivals.where((a) => a.arriveAt.isAfter(from)).toList();
  }

  /// Share of on-time arrivals in the last 30 days, or null without data.
  double? get onTimeRate30 {
    final l = _lastDays(30);
    return l.isEmpty ? null : l.where((a) => a.onTime).length / l.length;
  }

  /// The same for the first 5 missions ever: the "na starcie" baseline.
  double? get onTimeRateStart {
    final l = _arrivals.take(5).toList();
    return l.isEmpty ? null : l.where((a) => a.onTime).length / l.length;
  }

  double? get avgLate30 {
    final l = _lastDays(30);
    return l.isEmpty ? null : l.fold(0, (a, r) => a + r.lateMinutes) / l.length;
  }

  double? get avgLateStart {
    final l = _arrivals.take(5).toList();
    return l.isEmpty ? null : l.fold(0, (a, r) => a + r.lateMinutes) / l.length;
  }

  /// Total minutes late per week for the last [weeks] weeks, oldest first.
  List<int> weeklyLateMinutes({int weeks = 8}) {
    final n = now();
    final today = DateTime(n.year, n.month, n.day);
    final monday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    return [
      for (var w = weeks - 1; w >= 0; w--)
        _arrivals
            .where((a) {
              final start = DateTime(
                monday.year,
                monday.month,
                monday.day - 7 * w,
              );
              final end = DateTime(start.year, start.month, start.day + 7);
              return !a.arriveAt.isBefore(start) && a.arriveAt.isBefore(end);
            })
            .fold(0, (s, a) => s + a.lateMinutes),
    ];
  }

  /// Last 14 days, oldest first: null (no mission), true (all on time),
  /// false (at least one late).
  List<bool?> lastTwoWeeks() {
    final n = now();
    return [
      for (var d = 13; d >= 0; d--)
        () {
          final day = DateTime(n.year, n.month, n.day - d);
          final l = _arrivals.where(
            (a) =>
                a.arriveAt.year == day.year &&
                a.arriveAt.month == day.month &&
                a.arriveAt.day == day.day,
          );
          if (l.isEmpty) return null;
          return l.every((a) => a.onTime);
        }(),
    ];
  }
}
