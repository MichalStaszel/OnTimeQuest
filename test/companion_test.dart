import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ontime_quest/art/companion_art.dart';
import 'package:ontime_quest/art/sprites.dart';
import 'package:ontime_quest/models/companion.dart';
import 'package:ontime_quest/screens/home_shell.dart';

import 'helpers.dart';

void main() {
  test('something new to see every few on-time arrivals', () {
    expect(nextUnlock(tikoSpecies, 0)!.name, 'Pisklak');
    expect(nextUnlock(tikoSpecies, 1)!.name, 'Szalik');
    expect(nextUnlock(carSpecies, 3)!.name, 'Po myjni');
    expect(nextUnlock(tikoSpecies, 10)!.name, 'Tiko');
    expect(unlockedBetween(carSpecies, 0, 2), ['Na chodzie', 'Paski rajdowe']);
    expect(perksFor(7), {'outfit', 'sparkles', 'badge'});
  });

  test('hat shows from the first stage, on the car too', () {
    for (final sp in ['tiko', 'car']) {
      for (var st = 0; st < 5; st++) {
        final bare = composeCompanion(CompanionLook(species: sp, stage: st));
        final hat = composeCompanion(
          CompanionLook(species: sp, stage: st, hat: true),
        );
        expect(hat.length, greaterThan(bare.length), reason: '$sp $st');
      }
    }
  });

  test('perks change the sprite', () {
    const base = CompanionLook(species: 'car', stage: 1);
    final plain = composeCompanion(base);
    final rims = composeCompanion(
      const CompanionLook(species: 'car', stage: 1, perks: {'badge'}),
    );
    expect(rims, isNot(plain));
    final scarf = composeCompanion(
      const CompanionLook(stage: 2, perks: {'outfit'}),
    );
    expect(scarf.join().contains('r'), isTrue);
    expect(Sprites.tiko.join().contains('R'), isFalse);
  });

  testWidgets('car and minimal mode from settings', (t) async {
    final clock = TestClock();
    final app = await bootApp(t, clock);
    await t.tap(find.byIcon(Icons.settings_outlined));
    await t.pumpAndSettle();
    await tapText(t, 'Kaszlak (auto)');
    expect(app.species.id, 'car');
    expect(find.text('Kaszlak'), findsWidgets); // tab label

    await t.scrollUntilVisible(
      find.text('Tryb minimalny'),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    await t.tap(find.text('Tryb minimalny'));
    await t.pumpAndSettle();
    expect(app.minimal, isTrue);
    Navigator.of(t.element(find.text('Tryb minimalny'))).pop();
    await t.pumpAndSettle();
    expect(find.text('Kaszlak'), findsNothing);
    expect(find.text('Najedzony'), findsNothing);

    // Countdown and reward without the game parts.
    await tapText(t, 'Zacznij teraz · +20 za wcześniejszy start');
    expect(find.textContaining('jabłko'), findsNothing);
    for (var i = 0; i < 5; i++) {
      clock.now = clock.now.add(const Duration(minutes: 10));
      await tapText(t, 'Gotowe');
    }
    expect(find.text('Zdobyte punkty'), findsNothing);
    await tapText(t, 'Gotowe');
    expect(app.arrivals.length, 1);
    expect(HomeShell.tab.value, HomeShell.today);
  });
}
