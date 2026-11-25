import 'dart:math' as math;
import 'dart:typed_data';

import 'cues.dart';

/// Tiny 8-bit style jingles, synthesised in code so no audio files are
/// needed. Square wave, short envelope, 22 kHz mono WAV.
class Note {
  const Note(this.hz, this.ms);
  final double hz; // 0 = rest
  final int ms;
}

const _c5 = 523.25, _e5 = 659.25, _g5 = 783.99, _c6 = 1046.5;
const _a4 = 440.0, _f4 = 349.23, _d5 = 587.33, _e4 = 329.63;

List<Note>? melodyFor(CueKind k) => switch (k) {
  CueKind.blockStart => const [Note(_c5, 80), Note(_g5, 120)],
  CueKind.leaveHome => const [
    Note(_c5, 90),
    Note(_e5, 90),
    Note(_g5, 90),
    Note(_e5, 90),
    Note(_g5, 160),
  ],
  CueKind.twoMinutesLeft => const [Note(_a4, 110), Note(0, 70), Note(_a4, 110)],
  CueKind.tick => const [Note(_c6, 60)],
  CueKind.timeUp => const [Note(_d5, 140), Note(_a4, 140), Note(_f4, 220)],
  CueKind.doneInTime => const [Note(_e5, 70), Note(_g5, 70), Note(_c6, 160)],
  CueKind.doneLate => const [Note(_e4, 80), Note(_a4, 140)],
  CueKind.missionDone => const [
    Note(_c5, 100),
    Note(_e5, 100),
    Note(_g5, 100),
    Note(_c6, 140),
    Note(0, 60),
    Note(_g5, 90),
    Note(_c6, 260),
  ],
};

const _rate = 22050;

/// Renders notes to a complete WAV file.
Uint8List renderWav(List<Note> notes, {double volume = 0.35}) {
  final samples = <int>[];
  for (final n in notes) {
    final count = _rate * n.ms ~/ 1000;
    for (var i = 0; i < count; i++) {
      if (n.hz == 0) {
        samples.add(0);
        continue;
      }
      final t = i / _rate;
      final square = (t * n.hz) % 1 < 0.5 ? 1.0 : -1.0;
      // Quick attack, gentle decay: soft, not a harsh alarm.
      final attack = math.min(1.0, i / (_rate * 0.004));
      final decay = math.pow(1 - i / count, 1.5).toDouble();
      samples.add((square * attack * decay * volume * 32767).round());
    }
  }
  final data = ByteData(44 + samples.length * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, _rate, Endian.little);
  data.setUint32(28, _rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return data.buffer.asUint8List();
}
