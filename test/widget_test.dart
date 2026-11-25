import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

void main() {
  testWidgets('onboarding -> today -> countdown -> reward -> Tiko', (t) async {
    final clock = TestClock();
    final app = await bootApp(t, clock, onboarded: false);

    expect(find.text('Cześć! Jak masz na imię?'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'Michał');
    await tapText(t, 'Dalej');
    expect(
      find.text('Kto będzie pilnował czasu razem z tobą?'),
      findsOneWidget,
    );
    await tapText(t, 'Wybieram Tiko');

    expect(find.text('Dzień dobry, Michał'), findsOneWidget);
    expect(find.text('Dentysta · bądź o 12:00'), findsOneWidget);
    await tapText(t, 'Zacznij teraz · +20 za wcześniejszy start');
    expect(find.text('Etap 1 z 5'), findsOneWidget);
    expect(find.text('Śniadanie'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      clock.now = clock.now.add(const Duration(minutes: 10));
      await tapText(t, 'Gotowe');
    }
    expect(find.text('Jesteś na miejscu 10:10'), findsOneWidget);
    expect(find.text('Start przed planem'), findsOneWidget);

    await tapText(t, 'Nakarm Tiko');
    expect(app.companion.coins, greaterThan(100));
    expect(find.text('Pisklak'), findsWidgets);
  });
}
