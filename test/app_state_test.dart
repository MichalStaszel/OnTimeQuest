import 'package:flutter_test/flutter_test.dart';
import 'package:ontime_quest/data/local_store.dart';
import 'package:ontime_quest/logic/format.dart';
import 'package:ontime_quest/models/companion.dart';
import 'package:ontime_quest/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime clock;
  Future<AppState> make() async {
    SharedPreferences.setMockInitialValues({});
    return AppState(await LocalStore.open(), clock: () => clock);
  }

  /// Plays the next mission; the shower always takes [shower] minutes,
  /// everything else exactly as planned.
  void play(AppState app, {int shower = 25, bool plusFive = false}) {
    final m = app.nextMission!;
    clock = m.startAt;
    app.startSession(m);
    if (plusFive) app.addFiveMinutes();
    while (!app.session!.finished) {
      final cur = app.session!.current;
      clock = clock.add(
        Duration(minutes: cur.name == 'Prysznic' ? shower : cur.minutes),
      );
      app.completeStep();
    }
  }

  setUp(() => clock = DateTime(2026, 11, 25, 8, 0));

  test(
    'first launch: sample dentist mission at 12:00 starts at 09:55',
    () async {
      final app = await make();
      expect(app.companion.onboarded, isFalse);
      final m = app.nextMission!;
      expect(m.title, 'Dentysta');
      expect(hhmm(m.startAt), '09:55');
      app.completeOnboarding(name: 'Michał', companionId: 'tiko');
      expect(app.companion.onboarded, isTrue);
      expect(app.stage, 0);
    },
  );

  test('missions: next one and later today', () async {
    final app = await make();
    final gym = app.draftMission().copyWith(
      title: 'Siłownia',
      day: DateTime(2026, 11, 25),
      arriveHour: 18,
      arriveMinute: 30,
      steps: app.stepsFromSet(app.sets.last),
    );
    app.saveMission(gym);
    expect(app.nextMission!.title, 'Dentysta');
    expect(app.laterToday.map((m) => m.title), ['Siłownia']);
    clock = DateTime(2026, 11, 25, 14);
    expect(app.nextMission!.title, 'Siłownia');
  });

  test('a full mission pays out the itemised reward and food', () async {
    final app = await make();
    play(app, shower: 21);
    expect(app.sessionOnTimeByClock, isTrue);
    final r = app.reportArrival(onTime: true);
    // 100 on time + 8 (shower 4 min faster) + 20 without +5.
    expect(r.total, 128);
    expect(app.companion.coins, 128);
    expect(app.companion.food, {'apple': 5, 'cookie': 1});
    expect(app.missions, isEmpty);
    expect(app.stage, 1); // hatched
  });

  test('late by the clock; honest late earns +10', () async {
    final app = await make();
    play(app, shower: 40, plusFive: true);
    expect(app.sessionOnTimeByClock, isFalse);
    final r = app.reportArrival(onTime: false);
    expect(r.total, 10);
    expect(app.arrivals.single.lateMinutes, 15);
    expect(app.avgLate30, 15);
  });

  test(
    'learning: suggestion after 3 runs, accepting updates block and pays +15',
    () async {
      final app = await make();
      for (var d = 0; d < 3; d++) {
        clock = DateTime(2026, 11, 25 + d, 8);
        if (app.nextMission == null) {
          app.saveMission(
            app.draftMission().copyWith(
              title: 'Praca',
              day: DateTime(2026, 11, 25 + d),
              arriveHour: 12,
              arriveMinute: 0,
              steps: app.stepsFromSet(app.sets.first),
            ),
          );
        }
        play(app, shower: 32);
        app.reportArrival(onTime: true);
      }
      expect(app.suggestionFor('b-shower', 25), 32);
      final before = app.companion.coins;
      app.applySuggestion('b-shower', 32);
      expect(app.blockById('b-shower')!.minutes, 32);
      expect(app.companion.coins, before + 15);
      expect(app.learned.single.from, 25);
      expect(app.streak, 3);
    },
  );

  test('shop and feeding; fullness never drops below the floor', () async {
    final app = await make();
    play(app);
    app.reportArrival(onTime: true);
    expect(app.buy(shopItems.firstWhere((i) => i.id == 'lamp')), isFalse);
    expect(app.buy(shopItems.firstWhere((i) => i.id == 'apple')), isTrue);
    expect(app.companion.food['apple'], 5 + 3);
    final f = app.fullness;
    expect(app.feed(), isTrue); // cookie first
    expect(app.fullness, closeTo((f + 0.25).clamp(0, 1), 1e-9));
    clock = clock.add(const Duration(days: 60));
    expect(app.fullness, greaterThanOrEqualTo(fullnessFloor));
  });

  test('session survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.open();
    final a = AppState(store, clock: () => clock);
    a.startSession(a.nextMission!);
    a.addFiveMinutes();
    final b = AppState(store, clock: () => clock);
    expect(b.session!.extraMinutes, 5);
    expect(b.session!.startedEarly, isTrue);
  });
}
