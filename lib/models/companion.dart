import 'dart:math' as math;

/// Evolution stages, unlocked by the number of on-time arrivals
/// (not points, so it can't be "clicked out").
class Stage {
  const Stage(this.name, this.onTimeNeeded, this.description);
  final String name;
  final int onTimeNeeded;
  final String description;
}

/// Tiko's stages. Kept as the default list; see [Species.stages].
const stages = [
  Stage('Jajko', 0, 'Wykluwa się po pierwszej misji na czas.'),
  Stage('Pisklak', 1, 'Uczy się chodzić razem z tobą.'),
  Stage('Tiko', 15, 'Dzwonki, pierwsze ubranka.'),
  Stage('Wędrowiec', 40, 'Szalik, plecak, nowe sceny.'),
  Stage('???', 100, 'Niespodzianka po 3 miesiącach.'),
];

const carStages = [
  Stage('Wrak', 0, 'Stoi w garażu. Odpala po pierwszej misji na czas.'),
  Stage('Na chodzie', 1, 'Jeździ! Trochę kaszle, ale jedzie.'),
  Stage('Odpicowany', 15, 'Nowy lakier i chromy.'),
  Stage('Rajdówka', 40, 'Spojler i sportowy wydech.'),
  Stage('???', 100, 'Niespodzianka po 3 miesiącach.'),
];

/// A companion the user can pick. Same economy and stages for all of them,
/// only the look and the words differ.
class Species {
  const Species({
    required this.id,
    required this.name,
    required this.accusative,
    required this.genitive,
    required this.pickTitle,
    required this.pickText,
    required this.stages,
    required this.perkNames,
  });

  final String id;

  /// "Tiko" / "Kaszlak", as in "Tiko dostanie jabłko".
  final String name;

  /// "Nakarm Tiko" / "Nakarm Kaszlaka".
  final String accusative;

  /// "pokój Tiko" / "garaż Kaszlaka".
  final String genitive;
  final String pickTitle;
  final String pickText;
  final List<Stage> stages;

  /// Names of the [perks], in the same order.
  final List<String> perkNames;
}

const tikoSpecies = Species(
  id: 'tiko',
  name: 'Tiko',
  accusative: 'Tiko',
  genitive: 'Tiko',
  pickTitle: 'Tiko',
  pickText: 'Budzik-stworek. Ewoluuje w 5 etapach.',
  stages: stages,
  perkNames: ['Szalik', 'Iskierki', 'Złota gwiazdka', 'Poświata'],
);

const carSpecies = Species(
  id: 'car',
  name: 'Kaszlak',
  accusative: 'Kaszlaka',
  genitive: 'Kaszlaka',
  pickTitle: 'Garaż',
  pickText: 'Stary Kaszlak, którego odnawiasz część po części.',
  stages: carStages,
  perkNames: ['Paski rajdowe', 'Po myjni', 'Złote felgi', 'Neon'],
);

const allSpecies = [tikoSpecies, carSpecies];

Species speciesById(String? id) =>
    allSpecies.firstWhere((s) => s.id == id, orElse: () => tikoSpecies);

/// Small visible rewards between the big stages, so every few on-time
/// arrivals change how the companion looks. Unlocked automatically.
class Perk {
  const Perk(this.id, this.onTimeNeeded);
  final String id;
  final int onTimeNeeded;
}

const perks = [
  Perk('outfit', 2), // scarf / racing stripes
  Perk('sparkles', 4),
  Perk('badge', 7), // gold star / gold rims
  Perk('glow', 10),
];

Set<String> perksFor(int onTimeCount) => {
  for (final p in perks)
    if (onTimeCount >= p.onTimeNeeded) p.id,
};

/// The next visible reward (a perk or a stage), or null at the very end.
({String name, int needed})? nextUnlock(Species sp, int onTimeCount) {
  final options = <({String name, int needed})>[
    for (var i = 0; i < perks.length; i++)
      (name: sp.perkNames[i], needed: perks[i].onTimeNeeded),
    for (final st in sp.stages.skip(1))
      (name: st.name, needed: st.onTimeNeeded),
  ]..sort((a, b) => a.needed.compareTo(b.needed));
  for (final o in options) {
    if (o.needed > onTimeCount) return o;
  }
  return null;
}

/// What became visible when the count went from [before] to [after].
List<String> unlockedBetween(Species sp, int before, int after) => [
  for (var i = 1; i < sp.stages.length; i++)
    if (sp.stages[i].onTimeNeeded > before &&
        sp.stages[i].onTimeNeeded <= after)
      sp.stages[i].name,
  for (var i = 0; i < perks.length; i++)
    if (perks[i].onTimeNeeded > before && perks[i].onTimeNeeded <= after)
      sp.perkNames[i],
];

int stageFor(int onTimeCount) {
  var s = 0;
  for (var i = 0; i < stages.length; i++) {
    if (onTimeCount >= stages[i].onTimeNeeded) s = i;
  }
  return s;
}

enum ItemKind { food, wearable, room }

class ShopItem {
  const ShopItem(this.id, this.name, this.price, this.kind, {this.amount = 1});
  final String id;
  final String name;
  final int price;
  final ItemKind kind;

  /// For food: how many you get.
  final int amount;
}

const shopItems = [
  ShopItem('apple', 'Jabłko', 30, ItemKind.food, amount: 3),
  ShopItem('hat', 'Czapka', 200, ItemKind.wearable),
  ShopItem('plant', 'Monstera', 350, ItemKind.room),
  ShopItem('lamp', 'Lampka', 500, ItemKind.room),
];

/// How much one piece of food fills the companion up (0..1).
const foodValue = {'apple': 0.12, 'cookie': 0.25};

/// Fullness drops this much per day. It never reaches zero on its own and
/// the companion never gets sick or dies: no guilt, only less food.
const fullnessDecayPerDay = 0.15;
const fullnessFloor = 0.2;

/// Everything about the user's companion and wallet.
class CompanionState {
  const CompanionState({
    this.userName = '',
    this.companionId,
    this.coins = 0,
    this.food = const {},
    this.fullness = 0.6,
    this.fullnessAt,
    this.owned = const {},
    this.wearingHat = true,
    this.minimal = false,
  });

  final String userName;

  /// null until the user picks one in onboarding: 'tiko' or 'car'.
  final String? companionId;

  /// Minimal mode: no companion, shop or points on screen, just blocks
  /// and countdowns. Points are still counted in the background.
  final bool minimal;
  final int coins;
  final Map<String, int> food;
  final double fullness;
  final DateTime? fullnessAt;
  final Set<String> owned;
  final bool wearingHat;

  bool get onboarded => companionId != null;
  int get foodCount => food.values.fold(0, (a, b) => a + b);

  double fullnessNow(DateTime now) {
    if (fullnessAt == null) return fullness;
    final days = now.difference(fullnessAt!).inMinutes / (60 * 24);
    return math
        .max(
          math.min(fullness, fullnessFloor),
          fullness - days * fullnessDecayPerDay,
        )
        .clamp(0.0, 1.0);
  }

  CompanionState copyWith({
    String? userName,
    String? companionId,
    int? coins,
    Map<String, int>? food,
    double? fullness,
    DateTime? fullnessAt,
    Set<String>? owned,
    bool? wearingHat,
    bool? minimal,
  }) => CompanionState(
    userName: userName ?? this.userName,
    companionId: companionId ?? this.companionId,
    coins: coins ?? this.coins,
    food: food ?? this.food,
    fullness: fullness ?? this.fullness,
    fullnessAt: fullnessAt ?? this.fullnessAt,
    owned: owned ?? this.owned,
    wearingHat: wearingHat ?? this.wearingHat,
    minimal: minimal ?? this.minimal,
  );

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'companionId': companionId,
    'coins': coins,
    'food': food,
    'fullness': fullness,
    'fullnessAt': fullnessAt?.toIso8601String(),
    'owned': owned.toList(),
    'wearingHat': wearingHat,
    'minimal': minimal,
  };

  factory CompanionState.fromJson(Map<String, dynamic> j) => CompanionState(
    userName: j['userName'] as String? ?? '',
    companionId: j['companionId'] as String?,
    coins: j['coins'] as int? ?? 0,
    food:
        (j['food'] as Map?)?.map((k, v) => MapEntry(k as String, v as int)) ??
        const {},
    fullness: (j['fullness'] as num?)?.toDouble() ?? 0.6,
    fullnessAt: j['fullnessAt'] == null
        ? null
        : DateTime.parse(j['fullnessAt'] as String),
    owned: ((j['owned'] as List?) ?? const []).cast<String>().toSet(),
    wearingHat: j['wearingHat'] as bool? ?? true,
    minimal: j['minimal'] as bool? ?? false,
  );
}
