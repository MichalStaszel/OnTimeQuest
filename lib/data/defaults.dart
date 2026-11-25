import '../models/block.dart';
import '../models/plan.dart';

/// Starter content shown on first launch (the dentist morning from the mockups).
const defaultBlocks = [
  Block(id: 'b-breakfast', name: 'Śniadanie', minutes: 30, icon: 'cup'),
  Block(id: 'b-shower', name: 'Prysznic', minutes: 25, icon: 'shower'),
  Block(id: 'b-iron', name: 'Prasowanie', minutes: 15, icon: 'iron'),
  Block(id: 'b-dress', name: 'Ubieranie', minutes: 10, icon: 'shirt'),
  Block(id: 'b-buffer', name: 'Zapas', minutes: 10, icon: 'flag'),
  Block(id: 'b-commute', name: 'Dojazd', minutes: 45, icon: 'bus'),
  Block(id: 'b-pack', name: 'Pakowanie', minutes: 5, icon: 'flame'),
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

Plan defaultPlan() {
  const ids = ['b-breakfast', 'b-shower', 'b-iron', 'b-buffer', 'b-commute'];
  return Plan(
    title: 'Dentysta',
    arriveHour: 12,
    arriveMinute: 0,
    steps: [
      for (final (i, id) in ids.indexed)
        PlanStep.fromBlock(defaultBlocks.firstWhere((b) => b.id == id), 'p-$i'),
    ],
  );
}
