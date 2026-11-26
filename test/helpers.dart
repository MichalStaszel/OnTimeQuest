import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ontime_quest/app.dart';
import 'package:ontime_quest/data/local_store.dart';
import 'package:ontime_quest/screens/home_shell.dart';
import 'package:ontime_quest/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mutable test clock.
class TestClock {
  DateTime now = DateTime(2026, 11, 25, 9, 20);
  DateTime call() => now;
}

/// Boots the app on a phone-sized screen. [onboarded] skips the
/// companion pick.
Future<AppState> bootApp(
  WidgetTester t,
  TestClock clock, {
  bool onboarded = true,
}) async {
  t.view.physicalSize = const Size(1080, 2400);
  t.view.devicePixelRatio = 2.75;
  addTearDown(t.view.reset);
  HomeShell.tab.value = 0;
  SharedPreferences.setMockInitialValues({});
  final app = AppState(await LocalStore.open(), clock: clock.call);
  if (onboarded) app.completeOnboarding(name: 'Michał', companionId: 'tiko');
  await t.pumpWidget(
    ChangeNotifierProvider.value(value: app, child: const OnTimeQuestApp()),
  );
  await t.pumpAndSettle();
  return app;
}

Future<void> tapText(WidgetTester t, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    // Lazily built list: scroll until it is there.
    await t.scrollUntilVisible(
      find.text(text),
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await t.ensureVisible(find.text(text).last);
  await t.pumpAndSettle();
  await t.tap(find.text(text).last);
  await t.pumpAndSettle();
}
