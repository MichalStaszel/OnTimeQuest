import 'package:flutter_test/flutter_test.dart';
import 'package:ontime_quest/data/local_store.dart';
import 'package:ontime_quest/models/mission.dart';
import 'package:ontime_quest/models/run_session.dart';
import 'package:ontime_quest/notifications/mission_notice.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

RunSession session(DateTime start) => RunSession(
  missionId: 'm',
  title: 'Dentysta',
  arriveAt: DateTime(2026, 11, 25, 10),
  steps: const [
    PlanStep(id: 'a', name: 'Prysznic', minutes: 10, icon: 'shower'),
    PlanStep(id: 'b', name: 'Dojazd', minutes: 20, icon: 'bus'),
  ],
  index: 0,
  stepStartedAt: start,
);

void main() {
  final t0 = DateTime(2026, 11, 25, 9);

  test('ongoing notice: progress, countdown target, next block', () {
    final n = missionNotice(session(t0), t0.add(const Duration(minutes: 5)));
    expect(n.title, 'Prysznic · etap 1 z 2');
    expect(n.progress, 500);
    expect(n.endsAt, t0.add(const Duration(minutes: 10)));
    expect(n.over, isFalse);
    expect(n.body, contains('Dalej: Dojazd, 20 min'));
    expect(n.body, contains('cel 10:00'));
    expect(n.payload, 'm#0');

    final late = missionNotice(
      session(t0),
      t0.add(const Duration(minutes: 12)),
    );
    expect(late.over, isTrue);
    expect(late.progress, MissionNotice.maxProgress);
    expect(late.body, startsWith('Czas etapu minął'));
  });

  test('prompts: 2 min before and at the end, only future ones', () {
    final s = session(t0);
    final p = promptsFor(s, t0);
    expect(p.map((e) => e.at), [
      t0.add(const Duration(minutes: 8)),
      t0.add(const Duration(minutes: 10)),
    ]);
    expect(p.first.title, 'Za 2 min koniec: Prysznic');
    expect(p.last.body, contains('Dojazd'));
    expect(promptsFor(s, t0.add(const Duration(minutes: 9))).length, 1);
    expect(promptsFor(s, t0, warn: false).length, 1);
  });

  testWidgets('Gotowe / +5 from a notification; stale ones are ignored', (
    t,
  ) async {
    final clock = TestClock();
    final app = await bootApp(t, clock);
    app.startSession(app.missions.first);
    final s = app.session!;
    final p = stepPayload(s);

    expect(
      app.applyNotificationAction(QueuedAction('plus5', p, clock.now)),
      true,
    );
    expect(app.session!.extraMinutes, 5);

    final at = clock.now.add(const Duration(minutes: 3));
    clock.now = clock.now.add(const Duration(minutes: 10));
    expect(app.applyNotificationAction(QueuedAction('done', p, at)), true);
    expect(app.session!.index, 1);
    // The step is timed by when the button was pressed, not when applied.
    expect(app.session!.stepStartedAt, at);

    // The same old notification pressed again does nothing.
    expect(app.applyNotificationAction(QueuedAction('done', p, at)), false);
    expect(app.session!.index, 1);
  });

  test('actions queued in the background are read once, in order', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.open();
    await LocalStore.queueAction(
      QueuedAction('done', 'm#0', t0.add(const Duration(minutes: 2))),
    );
    await LocalStore.queueAction(QueuedAction('plus5', 'm#0', t0));
    final got = await store.takeQueuedActions();
    expect(got.map((a) => a.action), ['plus5', 'done']);
    expect(await store.takeQueuedActions(), isEmpty);
  });
}
