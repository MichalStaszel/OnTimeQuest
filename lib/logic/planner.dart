import '../models/mission.dart';

/// A plan step placed on the clock.
class ScheduledStep {
  const ScheduledStep(this.step, this.start, this.end);

  final PlanStep step;
  final DateTime start;
  final DateTime end;
}

/// Result of planning backwards from the arrival time.
class Schedule {
  const Schedule({
    required this.startAt,
    required this.arriveAt,
    required this.steps,
  });

  /// When the first step must begin.
  final DateTime startAt;
  final DateTime arriveAt;
  final List<ScheduledStep> steps;

  int get totalMinutes => arriveAt.difference(startAt).inMinutes;
}

/// Core idea of the app: "I must be there at 12:00" -> when do I start?
///
/// Walks the steps from the last one to the first, subtracting each
/// duration from the arrival time.
Schedule planBackwards({
  required DateTime arriveAt,
  required List<PlanStep> steps,
}) {
  var cursor = arriveAt;
  final placed = <ScheduledStep>[];
  for (final step in steps.reversed) {
    final start = cursor.subtract(Duration(minutes: step.minutes));
    placed.add(ScheduledStep(step, start, cursor));
    cursor = start;
  }
  return Schedule(
    startAt: cursor,
    arriveAt: arriveAt,
    steps: placed.reversed.toList(),
  );
}

/// The next occurrence of [hour]:[minute]: today if it has not passed yet,
/// otherwise tomorrow.
DateTime nextOccurrence(int hour, int minute, DateTime now) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  return today.isAfter(now) ? today : today.add(const Duration(days: 1));
}

/// Median of real durations (in whole minutes) for a block, if there is
/// enough history and it differs from the planned value by [minDiff] minutes.
/// This is the "your shower takes 32 min, not 25" suggestion.
int? suggestedMinutes(
  List<int> actualSeconds, {
  required int plannedMinutes,
  int minSamples = 3,
  int window = 7,
  int minDiff = 3,
}) {
  if (actualSeconds.length < minSamples) return null;
  final recent = actualSeconds.length > window
      ? actualSeconds.sublist(actualSeconds.length - window)
      : List.of(actualSeconds);
  recent.sort();
  final mid = recent.length ~/ 2;
  final medianSec = recent.length.isOdd
      ? recent[mid]
      : (recent[mid - 1] + recent[mid]) ~/ 2;
  final minutes = (medianSec / 60).round();
  if (minutes < 1) return null;
  return (minutes - plannedMinutes).abs() >= minDiff ? minutes : null;
}

/// Consecutive days, ending with the most recent mission's day, on which
/// every mission was on time.
int currentStreak(List<({DateTime day, bool onTime})> results) {
  if (results.isEmpty) return 0;
  final byDay = <DateTime, bool>{};
  for (final r in results) {
    final d = DateTime(r.day.year, r.day.month, r.day.day);
    byDay[d] = (byDay[d] ?? true) && r.onTime;
  }
  final days = byDay.keys.toList()..sort();
  var streak = 0;
  DateTime? expected;
  for (final d in days.reversed) {
    if (expected != null && d != expected) break;
    if (!byDay[d]!) break;
    streak++;
    expected = DateTime(d.year, d.month, d.day - 1);
  }
  return streak;
}
