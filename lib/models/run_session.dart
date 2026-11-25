import '../logic/planner.dart';
import 'plan.dart';

/// A running countdown ("game"). Stored as timestamps, not ticking state,
/// so it survives the app being killed.
class RunSession {
  const RunSession({
    required this.title,
    required this.arriveAt,
    required this.steps,
    required this.index,
    required this.stepStartedAt,
    this.extraMinutes = 0,
    this.usedPlusFive = false,
  });

  final String title;
  final DateTime arriveAt;
  final List<PlanStep> steps;

  /// Index of the current step; equals steps.length when all are done.
  final int index;
  final DateTime stepStartedAt;

  /// Minutes added with "+5" to the current step.
  final int extraMinutes;
  final bool usedPlusFive;

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
  int minutesBehind(DateTime now) {
    final diff = projectedArrival(now).difference(arriveAt);
    return (diff.inSeconds / 60).ceil();
  }

  /// Where Tiko "should" be (0..1) along today's track, by the planned schedule.
  double plannedProgress(DateTime now) {
    final plan = planBackwards(arriveAt: arriveAt, steps: steps);
    final total = plan.arriveAt.difference(plan.startAt).inSeconds;
    if (total <= 0) return 1;
    return (now.difference(plan.startAt).inSeconds / total).clamp(0.0, 1.0);
  }

  /// Where the user actually is (0..1): finished steps plus the current one.
  double actualProgress(DateTime now) {
    final total = steps.fold<int>(0, (a, s) => a + s.minutes) * 60;
    if (total <= 0 || finished) return 1;
    final done = steps.take(index).fold<int>(0, (a, s) => a + s.minutes) * 60;
    final inStep = now
        .difference(stepStartedAt)
        .inSeconds
        .clamp(0, current.minutes * 60);
    return ((done + inStep) / total).clamp(0.0, 1.0);
  }

  RunSession copyWith({
    int? index,
    DateTime? stepStartedAt,
    int? extraMinutes,
    bool? usedPlusFive,
  }) => RunSession(
    title: title,
    arriveAt: arriveAt,
    steps: steps,
    index: index ?? this.index,
    stepStartedAt: stepStartedAt ?? this.stepStartedAt,
    extraMinutes: extraMinutes ?? this.extraMinutes,
    usedPlusFive: usedPlusFive ?? this.usedPlusFive,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'arriveAt': arriveAt.toIso8601String(),
    'steps': steps.map((s) => s.toJson()).toList(),
    'index': index,
    'stepStartedAt': stepStartedAt.toIso8601String(),
    'extraMinutes': extraMinutes,
    'usedPlusFive': usedPlusFive,
  };

  factory RunSession.fromJson(Map<String, dynamic> j) => RunSession(
    title: j['title'] as String,
    arriveAt: DateTime.parse(j['arriveAt'] as String),
    steps: (j['steps'] as List)
        .map((e) => PlanStep.fromJson(e as Map<String, dynamic>))
        .toList(),
    index: j['index'] as int,
    stepStartedAt: DateTime.parse(j['stepStartedAt'] as String),
    extraMinutes: j['extraMinutes'] as int? ?? 0,
    usedPlusFive: j['usedPlusFive'] as bool? ?? false,
  );
}
