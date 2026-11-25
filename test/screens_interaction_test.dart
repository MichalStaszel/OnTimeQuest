import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

/// Clicks through every screen to catch framework assertions (like the
/// disposed-controller crash Michał hit) before they reach a phone.
void main() {
  testWidgets(
    'new mission: title, time, day, set, block, reorder, dismiss, save',
    (t) async {
      final clock = TestClock();
      final app = await bootApp(t, clock);
      await tapText(t, 'Plan');
      await tapText(t, 'Nowa misja');
      expect(find.text('Nowa misja'), findsWidgets);

      await t.enterText(find.byType(TextField), 'Siłownia');
      await tapText(t, 'Muszę być');
      await tapText(t, 'OK');
      await tapText(t, 'dziś');
      await tapText(t, 'Użyj zestawu');
      await tapText(t, 'Wyjście na siłownię');
      expect(find.text('Pakowanie'), findsOneWidget);

      // minutes dialog on a step
      await tapText(t, 'Pakowanie');
      await t.tap(find.byIcon(Icons.add).last);
      await t.pump();
      await tapText(t, 'OK');
      expect(find.text('6'), findsOneWidget);

      // reorder by the handle
      final g = await t.startGesture(
        t.getCenter(find.byIcon(Icons.drag_indicator).first),
      );
      await t.pump(const Duration(milliseconds: 100));
      await g.moveBy(const Offset(0, 120));
      await t.pump(const Duration(milliseconds: 100));
      await g.up();
      await t.pumpAndSettle();

      // swipe to delete
      await t.drag(find.text('Zapas'), const Offset(-500, 0));
      await t.pumpAndSettle();
      expect(find.text('Zapas'), findsNothing);

      // add a block from the library sheet
      await tapText(t, 'dodaj blok');
      await tapText(t, 'Prysznic');
      expect(find.text('Prysznic'), findsOneWidget);

      await tapText(t, 'Zapisz');
      expect(app.missions.map((m) => m.title), contains('Siłownia'));
      expect(find.text('Siłownia'), findsOneWidget);
    },
  );

  testWidgets('new block from the mission sheet, then block library editing', (
    t,
  ) async {
    final clock = TestClock();
    final app = await bootApp(t, clock);
    await tapText(t, 'Plan');
    await tapText(t, 'Dentysta');
    await tapText(t, 'dodaj blok');
    await tapText(t, 'Nowy blok');
    await t.enterText(find.byType(TextField).last, 'Kawa');
    await t.tap(find.byIcon(Icons.add).last);
    await t.pump();
    await tapText(t, 'Zapisz');
    expect(app.blocks.any((b) => b.name == 'Kawa' && b.minutes == 11), isTrue);
    expect(find.text('Kawa'), findsOneWidget);
    await tapText(t, 'Anuluj');

    await tapText(t, 'Bloki');
    await tapText(t, 'Kawa');
    await tapText(t, 'Usuń blok');
    await tapText(t, 'Usuń');
    expect(app.blocks.any((b) => b.name == 'Kawa'), isFalse);

    await tapText(t, 'Poranek do pracy');
    await t.tap(find.byIcon(Icons.close).first);
    await t.pumpAndSettle();
    await tapText(t, 'Zapisz');
  });

  testWidgets('countdown: +5 and abort; shop and progress tabs', (t) async {
    final clock = TestClock();
    final app = await bootApp(t, clock);
    await tapText(t, 'Zacznij teraz · +20 za wcześniejszy start');
    await tapText(t, '+5 min');
    expect(app.session!.extraMinutes, 5);
    await t.tap(find.byIcon(Icons.close));
    await t.pumpAndSettle();
    await tapText(t, 'Przerwij');
    expect(app.session, isNull);

    await tapText(t, 'Tiko');
    expect(find.text('Jajko'), findsWidgets);
    await tapText(t, 'Lampka');
    expect(find.textContaining('Brakuje'), findsOneWidget);

    await tapText(t, 'Postęp');
    expect(find.text('Średnie spóźnienie'), findsOneWidget);
  });

  testWidgets('late arrival: honest late, then correcting it back', (t) async {
    final clock = TestClock();
    final app = await bootApp(t, clock);
    await tapText(t, 'Zacznij teraz · +20 za wcześniejszy start');
    for (var i = 0; i < 5; i++) {
      clock.now = clock.now.add(const Duration(minutes: 40));
      await tapText(t, 'Gotowe');
    }
    expect(find.textContaining('Spóźnienie'), findsWidgets);
    expect(find.text('Uczciwe „spóźniłem się”'), findsOneWidget);
    await tapText(t, 'Byłem na czas');
    expect(find.text('Na czas'), findsOneWidget);
    await tapText(t, 'Spóźniłem się');
    await tapText(t, 'Nakarm Tiko');
    expect(app.arrivals.single.onTime, isFalse);
  });
}
