import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ontime_quest/app.dart';
import 'package:ontime_quest/data/local_store.dart';
import 'package:ontime_quest/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _planList = find
    .descendant(
      of: find.byType(ReorderableListView),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> scrollTo(WidgetTester t, String text) async {
  await t.scrollUntilVisible(find.text(text), 300, scrollable: _planList);
  await t.pumpAndSettle();
}

Future<AppState> boot(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final app = AppState(
    await LocalStore.open(),
    clock: () => DateTime(2026, 11, 25, 9, 50),
  );
  await tester.pumpWidget(
    ChangeNotifierProvider.value(value: app, child: const OnTimeQuestApp()),
  );
  await tester.pumpAndSettle();
  return app;
}

void main() {
  testWidgets('edit title dialog', (t) async {
    await boot(t);
    await t.tap(find.text('Dentysta'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Praca');
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(find.text('Praca'), findsOneWidget);
    // Michał's repro: open the same dialog again after renaming.
    await t.tap(find.text('Praca'));
    await t.pumpAndSettle();
    await t.tap(find.text('Anuluj'));
    await t.pumpAndSettle();
    expect(find.text('Praca'), findsOneWidget);
  });

  testWidgets('time picker', (t) async {
    await boot(t);
    await t.tap(find.text('12:00').first);
    await t.pumpAndSettle();
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
  });

  testWidgets('step minutes dialog', (t) async {
    await boot(t);
    await t.tap(find.text('Prysznic'));
    await t.pumpAndSettle();
    await t.tap(find.text('+5'));
    await t.pump();
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(find.text('30'), findsWidgets);
  });

  testWidgets('dismiss step', (t) async {
    await boot(t);
    await t.drag(find.text('Prasowanie'), const Offset(-500, 0));
    await t.pumpAndSettle();
    expect(find.text('Prasowanie'), findsNothing);
  });

  testWidgets('reorder step', (t) async {
    await boot(t);
    final handle = find.byIcon(Icons.drag_indicator).first;
    final g = await t.startGesture(t.getCenter(handle));
    await t.pump(const Duration(milliseconds: 100));
    await g.moveBy(const Offset(0, 150));
    await t.pump(const Duration(milliseconds: 100));
    await g.moveBy(const Offset(0, 100));
    await t.pump();
    await g.up();
    await t.pumpAndSettle();
  });

  testWidgets('add block and load set via sheets', (t) async {
    await boot(t);
    await scrollTo(t, 'blok');
    await t.tap(find.text('blok'));
    await t.pumpAndSettle();
    await t.tap(find.text('Ubieranie').last);
    await t.pumpAndSettle();
    await t.tap(find.text('wczytaj zestaw'));
    await t.pumpAndSettle();
    await t.tap(find.text('Poranek do pracy'));
    await t.pumpAndSettle();
    await scrollTo(t, 'zapisz jako zestaw');
    await t.tap(find.text('zapisz jako zestaw'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Nowy');
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
  });

  testWidgets('blocks tab: edit block, new block, sets editor', (t) async {
    await boot(t);
    await t.tap(find.text('Bloki'));
    await t.pumpAndSettle();
    await t.tap(find.text('Prysznic'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Kąpiel');
    await t.tap(find.text('ZAPISZ'));
    await t.pumpAndSettle();
    await t.tap(find.text('nowy blok'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Kawa');
    await t.tap(find.text('ZAPISZ'));
    await t.pumpAndSettle();
    await t.tap(find.text('Kawa'));
    await t.pumpAndSettle();
    await t.tap(find.text('Usuń'));
    await t.pumpAndSettle();
    await t.tap(find.text('Usuń').last);
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.text('Poranek do pracy'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.text('Poranek do pracy'));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.close).first);
    await t.pumpAndSettle();
    await t.tap(find.text('dodaj blok'));
    await t.pumpAndSettle();
    await t.tap(find.text('Zapas').last);
    await t.pumpAndSettle();
    await t.tap(find.text('ZAPISZ'));
    await t.pumpAndSettle();
    await t.tap(find.text('Plan'));
    await t.pumpAndSettle();
  });

  testWidgets('countdown +5 and abort, then progress tab', (t) async {
    await boot(t);
    await scrollTo(t, 'START GRY');
    await t.tap(find.text('START GRY'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('+5 MIN'));
    await t.pumpAndSettle();
    await t.tap(find.text('+5 MIN'));
    await t.pump(const Duration(seconds: 2));
    await t.tap(find.byIcon(Icons.close));
    await t.pumpAndSettle();
    await t.tap(find.text('Przerwij'));
    await t.pumpAndSettle();
    await t.tap(find.text('Postęp'));
    await t.pumpAndSettle();
  });
}
