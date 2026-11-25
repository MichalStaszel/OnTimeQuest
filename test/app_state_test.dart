import 'package:flutter_test/flutter_test.dart';
import 'package:ontime_quest/data/local_store.dart';
import 'package:ontime_quest/logic/format.dart';
import 'package:ontime_quest/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime clock;
  Future<AppState> make() async {
    SharedPreferences.setMockInitialValues({});
    return AppState(await LocalStore.open(), clock: () => clock);
  }

  setUp(() => clock = DateTime(2026, 11, 25, 8, 0));

  test('default plan: dentist at 12:00 starts at 09:55', () async {
    final app = await make();
    expect(app.plan.title, 'Dentysta');
    expect(hhmm(app.schedule.startAt), '09:55');
  });

  test('editing a step and reordering recomputes the start', () async {
    final app = await make();
    final shower = app.plan.steps[1];
    app.setStepMinutes(shower.id, 32);
    expect(hhmm(app.schedule.startAt), '09:48');
    app.moveStep(1, 0);
    expect(app.plan.steps.first.name, 'Prysznic');
  });

  test('sets load into the plan and skip deleted blocks', () async {
    final app = await make();
    final work = app.sets.firstWhere((s) => s.name == 'Poranek do pracy');
    app.deleteBlock('b-dress');
    app.loadSetIntoPlan(app.sets.firstWhere((s) => s.id == work.id));
    expect(app.plan.steps.map((s) => s.name), [
      'Śniadanie',
      'Prysznic',
      'Dojazd',
    ]);
  });

  test(
    'a full game: Done, +5, arrival points, then learning kicks in',
    () async {
      final app = await make();
      for (var day = 0; day < 3; day++) {
        clock = DateTime(2026, 11, 25 + day, 9, 55);
        app.startSession();
        final steps = app.session!.steps.length;
        for (var i = 0; i < steps; i++) {
          // The shower always takes 32 minutes.
          final minutes = app.session!.current.name == 'Prysznic'
              ? 32
              : app.session!.current.minutes;
          if (day == 0 && i == 0) app.addFiveMinutes();
          clock = clock.add(Duration(minutes: minutes));
          app.completeStep();
        }
        expect(app.session!.finished, isTrue);
        final r = app.reportArrival(onTime: true);
        expect(r.points, day == 0 ? 100 : 120 + 5 * day);
      }
      expect(app.streak, 3);
      final shower = app.plan.steps.firstWhere((s) => s.name == 'Prysznic');
      expect(app.suggestionFor(shower), 32);
      app.applySuggestion(shower, 32);
      expect(app.blockById('b-shower')!.minutes, 32);
    },
  );

  test('session survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.open();
    final a = AppState(store, clock: () => clock)..startSession();
    a.addFiveMinutes();
    final b = AppState(store, clock: () => clock);
    expect(b.session, isNotNull);
    expect(b.session!.extraMinutes, 5);
  });
}
