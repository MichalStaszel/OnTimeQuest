/// How long a block really took, recorded when the user taps "Gotowe".
class StepRecord {
  const StepRecord({
    required this.blockId,
    required this.name,
    required this.plannedMinutes,
    required this.actualSeconds,
    required this.finishedAt,
  });

  final String? blockId;
  final String name;
  final int plannedMinutes;
  final int actualSeconds;
  final DateTime finishedAt;

  Map<String, dynamic> toJson() => {
    'blockId': blockId,
    'name': name,
    'plannedMinutes': plannedMinutes,
    'actualSeconds': actualSeconds,
    'finishedAt': finishedAt.toIso8601String(),
  };

  factory StepRecord.fromJson(Map<String, dynamic> j) => StepRecord(
    blockId: j['blockId'] as String?,
    name: j['name'] as String,
    plannedMinutes: j['plannedMinutes'] as int,
    actualSeconds: j['actualSeconds'] as int,
    finishedAt: DateTime.parse(j['finishedAt'] as String),
  );
}

/// Result of one mission.
class ArrivalRecord {
  const ArrivalRecord({
    required this.title,
    required this.arriveAt,
    required this.arrivedAt,
    required this.onTime,
    required this.usedPlusFive,
    required this.points,
    this.lateMinutes = 0,
  });

  final String title;

  /// Target time.
  final DateTime arriveAt;

  /// When the last block was done (or the user confirmed arrival).
  final DateTime arrivedAt;
  final bool onTime;
  final bool usedPlusFive;
  final int points;
  final int lateMinutes;

  Map<String, dynamic> toJson() => {
    'title': title,
    'arriveAt': arriveAt.toIso8601String(),
    'arrivedAt': arrivedAt.toIso8601String(),
    'onTime': onTime,
    'usedPlusFive': usedPlusFive,
    'points': points,
    'lateMinutes': lateMinutes,
  };

  factory ArrivalRecord.fromJson(Map<String, dynamic> j) {
    final arriveAt = DateTime.parse(j['arriveAt'] as String);
    return ArrivalRecord(
      title: j['title'] as String,
      arriveAt: arriveAt,
      arrivedAt: j['arrivedAt'] == null
          ? arriveAt
          : DateTime.parse(j['arrivedAt'] as String),
      onTime: j['onTime'] as bool,
      usedPlusFive: j['usedPlusFive'] as bool? ?? false,
      points: j['points'] as int? ?? 0,
      lateMinutes: j['lateMinutes'] as int? ?? 0,
    );
  }
}

/// A block whose duration the app corrected from history ("25 → 32").
class LearnedBlock {
  const LearnedBlock(this.blockId, this.name, this.icon, this.from, this.to);
  final String blockId;
  final String name;
  final String icon;
  final int from;
  final int to;

  Map<String, dynamic> toJson() => {
    'blockId': blockId,
    'name': name,
    'icon': icon,
    'from': from,
    'to': to,
  };
  factory LearnedBlock.fromJson(Map<String, dynamic> j) => LearnedBlock(
    j['blockId'] as String,
    j['name'] as String,
    j['icon'] as String? ?? 'glass',
    j['from'] as int,
    j['to'] as int,
  );
}
