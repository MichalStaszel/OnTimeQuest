import 'package:flutter_test/flutter_test.dart';
import 'package:ontime_quest/audio/chiptune.dart';
import 'package:ontime_quest/audio/cues.dart';
import 'package:ontime_quest/audio/sound_settings.dart';
import 'package:ontime_quest/audio/voice_lines.dart';
import 'package:ontime_quest/models/mission.dart';
import 'package:ontime_quest/models/run_session.dart';

RunSession session(DateTime start, {int index = 0}) => RunSession(
  missionId: 'm',
  title: 'Dentysta',
  arriveAt: start.add(const Duration(hours: 1)),
  steps: const [
    PlanStep(id: 'a', name: 'Prysznic', minutes: 10, icon: 'shower'),
    PlanStep(id: 'b', name: 'Dojazd', minutes: 20, icon: 'bus'),
  ],
  index: index,
  stepStartedAt: start,
);

List<CueKind> kinds(List<Cue> c) => c.map((e) => e.kind).toList();

void main() {
  final t0 = DateTime(2026, 11, 25, 9);

  test('cues fire once, in order, through a block', () {
    final tr = CueTracker();
    final s = session(t0);
    expect(kinds(tr.update(s, t0)), [CueKind.blockStart]);
    expect(tr.update(s, t0.add(const Duration(minutes: 5))), isEmpty);
    expect(kinds(tr.update(s, t0.add(const Duration(minutes: 8)))), [
      CueKind.twoMinutesLeft,
    ]);
    expect(
      tr.update(s, t0.add(const Duration(minutes: 8, seconds: 30))),
      isEmpty,
    );
    expect(
      kinds(tr.update(s, t0.add(const Duration(minutes: 9, seconds: 58)))),
      [CueKind.tick],
    );
    expect(kinds(tr.update(s, t0.add(const Duration(minutes: 10)))), [
      CueKind.timeUp,
    ]);
    expect(tr.update(s, t0.add(const Duration(minutes: 11))), isEmpty);
  });

  test('done in time, then leaving home, then finish', () {
    final tr = CueTracker();
    tr.update(session(t0), t0);
    final t1 = t0.add(const Duration(minutes: 7));
    final next = session(
      t0,
      index: 1,
    ).copyWith(stepStartedAt: t1, blocksInTime: 1);
    expect(kinds(tr.update(next, t1)), [CueKind.doneInTime, CueKind.leaveHome]);
    final t2 = t1.add(const Duration(minutes: 25));
    final done = next.copyWith(index: 2, stepStartedAt: t2, finishedAt: t2);
    expect(kinds(tr.update(done, t2)), [CueKind.missionDone]);
  });

  test('opening the screen mid-block does not replay old cues', () {
    final tr = CueTracker();
    expect(
      tr.update(session(t0), t0.add(const Duration(minutes: 12))),
      isEmpty,
    );
  });

  test('+5 re-arms the two-minute warning', () {
    final tr = CueTracker();
    final s = session(t0);
    tr.update(s, t0);
    tr.update(s, t0.add(const Duration(minutes: 8)));
    final plus = s.copyWith(extraMinutes: 5, usedPlusFive: true);
    expect(kinds(tr.update(plus, t0.add(const Duration(minutes: 13)))), [
      CueKind.twoMinutesLeft,
    ]);
  });

  test('every narrator has a line for every spoken cue', () {
    for (final n in [Narrator.male, Narrator.female]) {
      for (final k in CueKind.values.where((k) => k != CueKind.tick)) {
        expect(pickLine(n, k), isNotNull, reason: '$n $k');
      }
    }
    final ids = [
      for (final m in voiceLines.values)
        for (final l in m.values) ...l.map((e) => e.id),
    ];
    expect(ids.toSet().length, ids.length, reason: 'clip ids must be unique');
  });

  test('Polish minutes and filled lines', () {
    expect(minutesSpoken(1), '1 minuta');
    expect(minutesSpoken(3), '3 minuty');
    expect(minutesSpoken(25), '25 minut');
    expect(minutesSpoken(22), '22 minuty');
    const l = VoiceLine('x', '{name}. Masz {min}.');
    expect(
      l.fill(const Cue(CueKind.blockStart, name: 'Prysznic', minutes: 10)),
      'Prysznic. Masz 10 minut.',
    );
  });

  test('jingles render as valid WAV', () {
    for (final k in CueKind.values) {
      final wav = renderWav(melodyFor(k)!);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(wav.length, greaterThan(44));
    }
  });

  test('settings round-trip', () {
    const s = SoundSettings(beeps: false, narrator: Narrator.male);
    final back = SoundSettings.fromJson(s.toJson());
    expect(back.beeps, false);
    expect(back.narrator, Narrator.male);
    expect(
      const SoundSettings(beeps: false, narrator: Narrator.none).silent,
      true,
    );
  });
}
