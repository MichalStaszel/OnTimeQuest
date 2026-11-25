import 'dart:math' as math;

/// Evolution stages, unlocked by the number of on-time arrivals
/// (not points, so it can't be "clicked out").
class Stage {
  const Stage(this.name, this.onTimeNeeded, this.description);
  final String name;
  final int onTimeNeeded;
  final String description;
}

const stages = [
  Stage('Jajko', 0, 'Wykluwa się po pierwszej misji na czas.'),
  Stage('Pisklak', 1, 'Uczy się chodzić razem z tobą.'),
  Stage('Tiko', 15, 'Dzwonki, pierwsze ubranka.'),
  Stage('Wędrowiec', 40, 'Szalik, plecak, nowe sceny.'),
  Stage('???', 100, 'Niespodzianka po 3 miesiącach.'),
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
  });

  final String userName;

  /// null until the user picks one in onboarding. Only 'tiko' for now.
  final String? companionId;
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
  }) => CompanionState(
    userName: userName ?? this.userName,
    companionId: companionId ?? this.companionId,
    coins: coins ?? this.coins,
    food: food ?? this.food,
    fullness: fullness ?? this.fullness,
    fullnessAt: fullnessAt ?? this.fullnessAt,
    owned: owned ?? this.owned,
    wearingHat: wearingHat ?? this.wearingHat,
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
  );
}
