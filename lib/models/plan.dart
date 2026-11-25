import 'block.dart';

/// One step of today's plan. A copy of a [Block] so that changing the
/// minutes for today does not change the reusable block.
class PlanStep {
  const PlanStep({
    required this.id,
    required this.name,
    required this.minutes,
    required this.icon,
    this.blockId,
  });

  /// Unique per step (the same block can appear twice).
  final String id;
  final String name;
  final int minutes;
  final String icon;

  /// The library block this step came from, used for duration learning.
  final String? blockId;

  factory PlanStep.fromBlock(Block b, String id) => PlanStep(
    id: id,
    name: b.name,
    minutes: b.minutes,
    icon: b.icon,
    blockId: b.id,
  );

  PlanStep copyWith({int? minutes}) => PlanStep(
    id: id,
    name: name,
    minutes: minutes ?? this.minutes,
    icon: icon,
    blockId: blockId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'minutes': minutes,
    'icon': icon,
    'blockId': blockId,
  };

  factory PlanStep.fromJson(Map<String, dynamic> j) => PlanStep(
    id: j['id'] as String,
    name: j['name'] as String,
    minutes: j['minutes'] as int,
    icon: j['icon'] as String? ?? 'flag',
    blockId: j['blockId'] as String?,
  );
}

/// Today's mission: where, by when, and which steps lead there.
class Plan {
  const Plan({
    required this.title,
    required this.arriveHour,
    required this.arriveMinute,
    required this.steps,
  });

  final String title;
  final int arriveHour;
  final int arriveMinute;
  final List<PlanStep> steps;

  Plan copyWith({
    String? title,
    int? arriveHour,
    int? arriveMinute,
    List<PlanStep>? steps,
  }) => Plan(
    title: title ?? this.title,
    arriveHour: arriveHour ?? this.arriveHour,
    arriveMinute: arriveMinute ?? this.arriveMinute,
    steps: steps ?? this.steps,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'arriveHour': arriveHour,
    'arriveMinute': arriveMinute,
    'steps': steps.map((s) => s.toJson()).toList(),
  };

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    title: j['title'] as String,
    arriveHour: j['arriveHour'] as int,
    arriveMinute: j['arriveMinute'] as int,
    steps: (j['steps'] as List)
        .map((e) => PlanStep.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
