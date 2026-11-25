/// Points economy from the design. Points come from real behaviour, nothing
/// is ever taken away, and an honest "I was late" still earns something.
abstract final class Points {
  static const onTime = 100;
  static const perMinuteEarly = 2;
  static const maxPerBlock = 10;
  static const startedEarly = 20;
  static const noPlusFive = 20;
  static const perStreakDay = 5;
  static const maxStreak = 50;
  static const honestLate = 10;
  static const acceptSuggestion = 15;
}

class RewardLine {
  const RewardLine(this.label, this.points);
  final String label;
  final int points;
}

class Reward {
  const Reward({
    required this.lines,
    required this.apples,
    required this.cookies,
  });
  final List<RewardLine> lines;
  final int apples;
  final int cookies;

  int get total => lines.fold(0, (a, l) => a + l.points);
}

/// A block finished before its planned time.
class EarlyBlock {
  const EarlyBlock(this.name, this.minutesEarly);
  final String name;
  final int minutesEarly;

  Map<String, dynamic> toJson() => {'name': name, 'minutesEarly': minutesEarly};
  factory EarlyBlock.fromJson(Map<String, dynamic> j) =>
      EarlyBlock(j['name'] as String, j['minutesEarly'] as int);
}

String _minutesWord(int n) => '$n min';

/// Builds the itemised reward shown after arrival.
Reward computeReward({
  required bool onTime,
  required bool usedPlusFive,
  required bool startedEarly,
  required List<EarlyBlock> earlyBlocks,
  required int blocksInTime,
  required int streakAfter,
}) {
  final lines = <RewardLine>[];
  if (onTime) {
    lines.add(const RewardLine('Na czas', Points.onTime));
  } else {
    lines.add(const RewardLine('Uczciwe „spóźniłem się”', Points.honestLate));
  }
  for (final b in earlyBlocks) {
    if (b.minutesEarly < 1) continue;
    final p = (b.minutesEarly * Points.perMinuteEarly).clamp(
      0,
      Points.maxPerBlock,
    );
    lines.add(
      RewardLine('${b.name} ${_minutesWord(b.minutesEarly)} szybciej', p),
    );
  }
  if (startedEarly) {
    lines.add(const RewardLine('Start przed planem', Points.startedEarly));
  }
  if (onTime && !usedPlusFive) {
    lines.add(const RewardLine('Bez użycia +5 min', Points.noPlusFive));
  }
  if (onTime && streakAfter > 1) {
    final p = (Points.perStreakDay * (streakAfter - 1)).clamp(
      0,
      Points.maxStreak,
    );
    lines.add(RewardLine('Seria $streakAfter dni', p));
  }
  return Reward(lines: lines, apples: blocksInTime, cookies: onTime ? 1 : 0);
}
