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

/// Answer to "Na czas?" after a mission.
class ArrivalRecord {
  const ArrivalRecord({
    required this.title,
    required this.arriveAt,
    required this.onTime,
    required this.usedPlusFive,
    required this.points,
  });

  final String title;
  final DateTime arriveAt;
  final bool onTime;
  final bool usedPlusFive;
  final int points;

  Map<String, dynamic> toJson() => {
    'title': title,
    'arriveAt': arriveAt.toIso8601String(),
    'onTime': onTime,
    'usedPlusFive': usedPlusFive,
    'points': points,
  };

  factory ArrivalRecord.fromJson(Map<String, dynamic> j) => ArrivalRecord(
    title: j['title'] as String,
    arriveAt: DateTime.parse(j['arriveAt'] as String),
    onTime: j['onTime'] as bool,
    usedPlusFive: j['usedPlusFive'] as bool? ?? false,
    points: j['points'] as int? ?? 0,
  );
}
