import 'package:flutter_test/flutter_test.dart';
import 'package:ontime_quest/logic/format.dart';
import 'package:ontime_quest/logic/planner.dart';
import 'package:ontime_quest/models/plan.dart';

PlanStep step(String name, int minutes) =>
    PlanStep(id: name, name: name, minutes: minutes, icon: 'flag');

void main() {
  group('planBackwards', () {
    test('dentist morning from the mockups starts at 09:55', () {
      final s = planBackwards(
        arriveAt: DateTime(2026, 11, 25, 12, 0),
        steps: [
          step('Śniadanie', 30),
          step('Prysznic', 25),
          step('Prasowanie', 15),
          step('Zapas', 10),
          step('Dojazd', 45),
        ],
      );
      expect(hhmm(s.startAt), '09:55');
      expect(s.steps.map((e) => hhmm(e.start)), [
        '09:55',
        '10:25',
        '10:50',
        '11:05',
        '11:15',
      ]);
      expect(hhmm(s.steps.last.end), '12:00');
      expect(s.totalMinutes, 125);
    });

    test('empty plan starts at arrival', () {
      final at = DateTime(2026, 11, 25, 8);
      expect(planBackwards(arriveAt: at, steps: []).startAt, at);
    });

    test('crosses midnight', () {
      final s = planBackwards(
        arriveAt: DateTime(2026, 11, 25, 0, 30),
        steps: [step('a', 45)],
      );
      expect(s.startAt, DateTime(2026, 11, 24, 23, 45));
    });
  });

  test('nextOccurrence rolls to tomorrow once the time passed', () {
    final now = DateTime(2026, 11, 25, 13, 0);
    expect(nextOccurrence(14, 0, now), DateTime(2026, 11, 25, 14));
    expect(nextOccurrence(12, 0, now), DateTime(2026, 11, 26, 12));
  });

  group('suggestedMinutes', () {
    test('needs at least 3 samples', () {
      expect(suggestedMinutes([32 * 60, 33 * 60], plannedMinutes: 25), isNull);
    });

    test('suggests the median of recent runs (shower 32, not 25)', () {
      final mins = [28, 34, 31, 35, 30, 33, 32];
      expect(
        suggestedMinutes([for (final m in mins) m * 60], plannedMinutes: 25),
        32,
      );
    });

    test('ignores small differences', () {
      expect(
        suggestedMinutes([26 * 60, 27 * 60, 26 * 60], plannedMinutes: 25),
        isNull,
      );
    });
  });

  group('points and streaks', () {
    test('points as on the mockup: 100 + 20 + streak 4 days = 135', () {
      expect(pointsFor(onTime: true, usedPlusFive: false, streak: 4), 135);
      expect(pointsFor(onTime: true, usedPlusFive: true, streak: 1), 100);
      expect(pointsFor(onTime: false, usedPlusFive: false, streak: 0), 0);
    });

    test('streak counts consecutive on-time days', () {
      final r = [
        (day: DateTime(2026, 11, 20), onTime: false),
        (day: DateTime(2026, 11, 21), onTime: true),
        (day: DateTime(2026, 11, 22), onTime: true),
        (day: DateTime(2026, 11, 23, 9), onTime: true),
        (day: DateTime(2026, 11, 23, 18), onTime: true),
      ];
      expect(currentStreak(r), 3);
      expect(
        currentStreak([...r, (day: DateTime(2026, 11, 24), onTime: false)]),
        0,
      );
      expect(
        currentStreak([...r, (day: DateTime(2026, 11, 26), onTime: true)]),
        1,
      );
    });
  });

  test('countdownLabel', () {
    expect(countdownLabel(const Duration(minutes: 24, seconds: 5)), '24:05');
    expect(countdownLabel(const Duration(seconds: -72)), '+01:12');
    expect(durationLabel(125), '2 h 05');
  });
}
