import '../logic/rewards.dart';
import 'mission.dart';

/// A running countdown ("game"). Stored as timestamps, not ticking state,
/// so it survives the app being killed.
class RunSession {
  const RunSession({
    required this.missionId,
    required this.title,
    required this.arriveAt,
    required this.steps,
    required this.index,
    required this.stepStartedAt,
    this.extraMinutes = 0,
    this.usedPlusFive = false,
    this.startedEarly = false,
    this.earlyBlocks = const [],
    this.blocksInTime = 0,
    this.finishedAt,
  });

  final String missionId;
  final String title;
  final DateTime arriveAt;
  final List<PlanStep> steps;

  /// Index of the current step; equals steps.length when all are done.
  final int index;
  final DateTime stepStartedAt;

  /// Minutes added with "+5" to the current step.
  final int extraMinutes;
  final bool usedPlusFive;
  final bool startedEarly;

  /// Blocks finished before their planned minutes (for +2/min points).
  final List<EarlyBlock> earlyBlocks;

  /// Blocks finished within their time (each one = an apple).
  final int blocksInTime;
  final DateTime? finishedAt;

  bool get finished => index >= steps.length;
  PlanStep get current => steps[index];
  PlanStep? get next => index + 1 < steps.length ? steps[index + 1] : null;

  int get allowedMinutes => current.minutes + extraMinutes;
  DateTime get stepEndsAt =>
      stepStartedAt.add(Duration(minutes: allowedMinutes));

  Duration remaining(DateTime now) => stepEndsAt.difference(now);

  /// When we will arrive if the remaining steps take exactly as planned.
  DateTime projectedArrival(DateTime now) {
    var t = stepEndsAt.isAfter(now) ? stepEndsAt : now;
    for (final s in steps.skip(index + 1)) {
      t = t.add(Duration(minutes: s.minutes));
    }
    return t;
  }

  /// Positive: minutes behind plan. Negative: minutes of slack.
  int minutesBehind(DateTime now) =>
      (projectedArrival(now).difference(arriveAt).inSeconds / 60).ceil();

  /// When the user must leave home: the start of the last step whose name
  /// sounds like travel, else null.
  DateTime? leaveAt() {
    var t = arriveAt;
    for (final s in steps.reversed) {
      t = t.subtract(Duration(minutes: s.minutes));
      if (s.icon == 'bus') return t;
    }
    return null;
  }

  RunSession copyWith({
    int? index,
    DateTime? stepStartedAt,
    int? extraMinutes,
    bool? usedPlusFive,
    List<EarlyBlock>? earlyBlocks,
    int? blocksInTime,
    DateTime? finishedAt,
  }) => RunSession(
    missionId: missionId,
    title: title,
    arriveAt: arriveAt,
    steps: steps,
    index: index ?? this.index,
    stepStartedAt: stepStartedAt ?? this.stepStartedAt,
    extraMinutes: extraMinutes ?? this.extraMinutes,
    usedPlusFive: usedPlusFive ?? this.usedPlusFive,
    startedEarly: startedEarly,
    earlyBlocks: earlyBlocks ?? this.earlyBlocks,
    blocksInTime: blocksInTime ?? this.blocksInTime,
    finishedAt: finishedAt ?? this.finishedAt,
  );

  Map<String, dynamic> toJson() => {
    'missionId': missionId,
    'title': title,
    'arriveAt': arriveAt.toIso8601String(),
    'steps': steps.map((s) => s.toJson()).toList(),
    'index': index,
    'stepStartedAt': stepStartedAt.toIso8601String(),
    'extraMinutes': extraMinutes,
    'usedPlusFive': usedPlusFive,
    'startedEarly': startedEarly,
    'earlyBlocks': earlyBlocks.map((e) => e.toJson()).toList(),
    'blocksInTime': blocksInTime,
    'finishedAt': finishedAt?.toIso8601String(),
  };

  factory RunSession.fromJson(Map<String, dynamic> j) => RunSession(
    missionId: j['missionId'] as String? ?? '',
    title: j['title'] as String,
    arriveAt: DateTime.parse(j['arriveAt'] as String),
    steps: (j['steps'] as List)
        .map((e) => PlanStep.fromJson(e as Map<String, dynamic>))
        .toList(),
    index: j['index'] as int,
    stepStartedAt: DateTime.parse(j['stepStartedAt'] as String),
    extraMinutes: j['extraMinutes'] as int? ?? 0,
    usedPlusFive: j['usedPlusFive'] as bool? ?? false,
    startedEarly: j['startedEarly'] as bool? ?? false,
    earlyBlocks: ((j['earlyBlocks'] as List?) ?? const [])
        .map((e) => EarlyBlock.fromJson(e as Map<String, dynamic>))
        .toList(),
    blocksInTime: j['blocksInTime'] as int? ?? 0,
    finishedAt: j['finishedAt'] == null
        ? null
        : DateTime.parse(j['finishedAt'] as String),
  );
}
