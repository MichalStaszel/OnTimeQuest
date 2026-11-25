import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ontime_quest/app.dart';
import 'package:ontime_quest/data/local_store.dart';
import 'package:ontime_quest/models/companion.dart';
import 'package:ontime_quest/screens/home_shell.dart';
import 'package:ontime_quest/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void main() {
  setUpAll(() async {
    await loadFont('Lexend', 'assets/fonts/Lexend.ttf');
    await loadFont('VT323', 'assets/fonts/VT323-Regular.ttf');
    await loadFont('MaterialIcons', '/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  });

  Future<void> settle(WidgetTester t) async {
    await t.pump(const Duration(milliseconds: 300));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
  }

  Future<void> shot(WidgetTester t, String name) async {
    await settle(t);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/$name.png'));
  }

  testWidgets('screens', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    var clock = DateTime(2026, 11, 3, 8, 0);
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await LocalStore.open(), clock: () => clock);
    await t.pumpWidget(ChangeNotifierProvider.value(value: app, child: const OnTimeQuestApp()));
    await shot(t, '01_onboarding_name');
    await t.enterText(find.byType(TextField), 'Michał');
    await t.tap(find.text('Dalej'));
    await shot(t, '02_onboarding_pick');
    await t.tap(find.text('Wybieram Tiko'));
    await t.pump();

    // three weeks of history: shower 32 min, a couple of late days
    app.deleteMission('m-sample');
    for (var d = 0; d < 21; d++) {
      clock = DateTime(2026, 11, 3 + d, 7, 0);
      final m = app.draftMission().copyWith(
        title: 'Praca',
        day: DateTime(2026, 11, 3 + d),
        arriveHour: 9,
        arriveMinute: 0,
        steps: app.stepsFromSet(app.sets.first),
      );
      app.saveMission(m);
      clock = m.startAt;
      app.startSession(m);
      final late = d == 1 || d == 4 || d == 9;
      while (!app.session!.finished) {
        final c = app.session!.current;
        clock = clock.add(Duration(minutes: c.name == 'Prysznic' ? (late ? 45 : 32) : c.minutes - (d > 10 ? 1 : 0)));
        app.completeStep();
      }
      app.reportArrival(onTime: app.sessionOnTimeByClock);
      if (d == 2) app.applySuggestion('b-shower', 32);
    }
    app.buy(shopItems.firstWhere((i) => i.id == 'plant'));
    app.buy(shopItems.firstWhere((i) => i.id == 'hat'));
    clock = DateTime(2026, 11, 25, 9, 20);
    app.saveMission(app.draftMission().copyWith(
      title: 'Dentysta',
      day: DateTime(2026, 11, 25),
      arriveHour: 12,
      arriveMinute: 0,
      steps: [
        for (final id in ['b-breakfast', 'b-shower', 'b-iron', 'b-buffer', 'b-commute'])
          ...app.stepsFromSet(app.sets.first).take(0),
      ],
    ));
    // build the dentist steps from blocks (shower back to 25 to show the hint)
    final dent = app.missions.firstWhere((m) => m.title == 'Dentysta');
    app.saveBlock(id: 'b-shower', name: 'Prysznic', minutes: 25, icon: 'shower');
    app.saveMission(dent.copyWith(steps: [
      for (final id in ['b-breakfast', 'b-shower', 'b-iron', 'b-buffer', 'b-commute'])
        app.stepsFromSet(app.sets.first.copyWith(blockIds: [id])).single,
    ]));
    app.saveMission(app.draftMission().copyWith(
      title: 'Siłownia',
      day: DateTime(2026, 11, 25),
      arriveHour: 18,
      arriveMinute: 30,
      steps: app.stepsFromSet(app.sets.last),
      setName: app.sets.last.name,
    ));
    await shot(t, '03_today');

    HomeShell.tab.value = HomeShell.plan;
    await t.pump();
    await t.tap(find.text('Dentysta'));
    await shot(t, '04_mission');
    await t.tap(find.text('Anuluj'));
    await settle(t);
    await t.tap(find.text('Bloki'));
    await settle(t);
    await t.tap(find.text('Prysznic'));
    await shot(t, '05_block_sheet');
    await t.tapAt(const Offset(20, 20));
    await settle(t);
    await t.pageBack();
    await settle(t);

    HomeShell.tab.value = HomeShell.today;
    await t.pump();
    clock = DateTime(2026, 11, 25, 9, 50);
    await t.tap(find.textContaining('Zacznij teraz'));
    await settle(t);
    clock = DateTime(2026, 11, 25, 10, 18);
    app.completeStep();
    clock = DateTime(2026, 11, 25, 10, 31, 40);
    await shot(t, '06_countdown');
    for (final m in [24, 15, 10, 40]) {
      clock = clock.add(Duration(minutes: m));
      app.completeStep();
      await settle(t);
    }
    clock = DateTime(2026, 11, 25, 11, 56);
    await t.pumpAndSettle();
    await shot(t, '07_reward');
    await t.tap(find.text('Nakarm Tiko'));
    await settle(t);
    await shot(t, '08_tiko');
    HomeShell.tab.value = HomeShell.progress;
    await shot(t, '09_progress');
  });
}
