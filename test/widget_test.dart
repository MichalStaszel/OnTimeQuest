import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ontime_quest/app.dart';
import 'package:ontime_quest/data/local_store.dart';
import 'package:ontime_quest/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('plan -> start game -> Done through all stages -> arrival', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.open();
    final app = AppState(store, clock: () => DateTime(2026, 11, 25, 9, 50));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: app, child: const OnTimeQuestApp()),
    );
    expect(find.text('Dentysta'), findsOneWidget);
    expect(find.text('09:55'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('START GRY'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ReorderableListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('START GRY'));
    await tester.pumpAndSettle();
    expect(find.text('ETAP 1/5'), findsOneWidget);
    expect(find.text('ŚNIADANIE'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tester.ensureVisible(find.text('GOTOWE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GOTOWE'));
      await tester.pumpAndSettle();
    }
    expect(find.text('NA CZAS?'), findsOneWidget);
    await tester.tap(find.text('TAK'));
    await tester.pumpAndSettle();
    expect(find.text('+120'), findsOneWidget);
  });
}
