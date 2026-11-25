import 'block.dart';

/// One step of a mission. A copy of a [Block] so that changing the minutes
/// for one mission does not change the reusable block.
class PlanStep {
  const PlanStep({
    required this.id,
    required this.name,
    required this.minutes,
    required this.icon,
    this.blockId,
    this.allowPlusFive = true,
  });

  /// Unique per step (the same block can appear twice).
  final String id;
  final String name;
  final int minutes;
  final String icon;

  /// The library block this step came from, used for duration learning.
  final String? blockId;
  final bool allowPlusFive;

  factory PlanStep.fromBlock(Block b, String id) => PlanStep(
    id: id,
    name: b.name,
    minutes: b.minutes,
    icon: b.icon,
    blockId: b.id,
    allowPlusFive: b.allowPlusFive,
  );

  PlanStep copyWith({int? minutes}) => PlanStep(
    id: id,
    name: name,
    minutes: minutes ?? this.minutes,
    icon: icon,
    blockId: blockId,
    allowPlusFive: allowPlusFive,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'minutes': minutes,
    'icon': icon,
    'blockId': blockId,
    'allowPlusFive': allowPlusFive,
  };

  factory PlanStep.fromJson(Map<String, dynamic> j) => PlanStep(
    id: j['id'] as String,
    name: j['name'] as String,
    minutes: j['minutes'] as int,
    icon: j['icon'] as String? ?? 'glass',
    blockId: j['blockId'] as String?,
    allowPlusFive: j['allowPlusFive'] as bool? ?? true,
  );
}

/// A mission: be at [title] on [day] at [arriveHour]:[arriveMinute],
/// with [steps] leading there.
class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.day,
    required this.arriveHour,
    required this.arriveMinute,
    required this.steps,
    this.setName,
  });

  final String id;
  final String title;

  /// Midnight of the mission's day.
  final DateTime day;
  final int arriveHour;
  final int arriveMinute;
  final List<PlanStep> steps;

  /// Name of the set it was built from, shown on Today ("zestaw ...").
  final String? setName;

  DateTime get arriveAt =>
      DateTime(day.year, day.month, day.day, arriveHour, arriveMinute);

  int get totalMinutes => steps.fold(0, (a, s) => a + s.minutes);

  DateTime get startAt => arriveAt.subtract(Duration(minutes: totalMinutes));

  Mission copyWith({
    String? title,
    DateTime? day,
    int? arriveHour,
    int? arriveMinute,
    List<PlanStep>? steps,
    String? setName,
  }) => Mission(
    id: id,
    title: title ?? this.title,
    day: day ?? this.day,
    arriveHour: arriveHour ?? this.arriveHour,
    arriveMinute: arriveMinute ?? this.arriveMinute,
    steps: steps ?? this.steps,
    setName: setName ?? this.setName,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'day': day.toIso8601String(),
    'arriveHour': arriveHour,
    'arriveMinute': arriveMinute,
    'steps': steps.map((s) => s.toJson()).toList(),
    'setName': setName,
  };

  factory Mission.fromJson(Map<String, dynamic> j) => Mission(
    id: j['id'] as String,
    title: j['title'] as String,
    day: DateTime.parse(j['day'] as String),
    arriveHour: j['arriveHour'] as int,
    arriveMinute: j['arriveMinute'] as int,
    steps: (j['steps'] as List)
        .map((e) => PlanStep.fromJson(e as Map<String, dynamic>))
        .toList(),
    setName: j['setName'] as String?,
  );
}
