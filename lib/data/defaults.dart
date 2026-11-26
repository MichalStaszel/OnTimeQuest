import '../models/block.dart';
import '../models/mission.dart';

/// Starter content shown on first launch (the dentist morning from the design).
const defaultBlocks = [
  Block(id: 'b-breakfast', name: 'Śniadanie', minutes: 30, icon: 'cup'),
  Block(id: 'b-shower', name: 'Prysznic', minutes: 25, icon: 'shower'),
  Block(id: 'b-iron', name: 'Prasowanie', minutes: 15, icon: 'iron'),
  Block(id: 'b-dress', name: 'Ubieranie', minutes: 10, icon: 'shirt'),
  Block(id: 'b-buffer', name: 'Zapas', minutes: 10, icon: 'glass'),
  Block(id: 'b-commute', name: 'Dojazd', minutes: 45, icon: 'bus'),
  Block(id: 'b-pack', name: 'Pakowanie', minutes: 5, icon: 'dumbbell'),
];

const defaultSets = [
  BlockSet(
    id: 's-work',
    name: 'Poranek do pracy',
    blockIds: ['b-breakfast', 'b-shower', 'b-dress', 'b-commute'],
  ),
  BlockSet(
    id: 's-gym',
    name: 'Wyjście na siłownię',
    blockIds: ['b-dress', 'b-pack', 'b-buffer', 'b-commute'],
  ),
];

/// A sample mission so the Today screen is not empty on first launch:
/// the dentist at 12:00, today if there is still time, otherwise tomorrow.
Mission sampleMission(DateTime now) {
  const ids = ['b-breakfast', 'b-shower', 'b-iron', 'b-buffer', 'b-commute'];
  final steps = [
    for (final (i, id) in ids.indexed)
      PlanStep.fromBlock(defaultBlocks.firstWhere((b) => b.id == id), 'p-$i'),
  ];
  var day = DateTime(now.year, now.month, now.day);
  final m = Mission(
    id: 'm-sample',
    title: 'Dentysta',
    day: day,
    arriveHour: 12,
    arriveMinute: 0,
    steps: steps,
  );
  if (m.startAt.isBefore(now)) day = DateTime(day.year, day.month, day.day + 1);
  return m.copyWith(day: day);
}
