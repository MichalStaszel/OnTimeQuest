import '../models/run_session.dart';

/// Moments in a mission that get a sound.
enum CueKind {
  /// A block starts (also the first one).
  blockStart,

  /// The block that ends with leaving home starts.
  leaveHome,

  /// Two minutes left in the block.
  twoMinutesLeft,

  /// 3, 2, 1 seconds before the block's time runs out.
  tick,

  /// The block's time just ran out.
  timeUp,

  /// "Gotowe" pressed in time: Tiko gets an apple.
  doneInTime,

  /// "Gotowe" pressed after the time ran out.
  doneLate,

  /// Last block done.
  missionDone,
}

class Cue {
  const Cue(this.kind, {this.name = '', this.minutes = 0});

  final CueKind kind;

  /// Name of the block the cue is about.
  final String name;
  final int minutes;

  @override
  String toString() => 'Cue(${kind.name}, $name, $minutes)';
}

/// Watches a running session and says which cues to play. Pure logic, no
/// audio: call [update] on every tick and play what it returns. Every cue
/// fires at most once, and nothing old is replayed when the screen opens
/// in the middle of a block.
class CueTracker {
  CueTracker({this.warnFor});

  /// Whether the block of a step wants the "2 minutes left" warning.
  final bool Function(int stepIndex)? warnFor;

  int? _index;
  int _inTime = 0;
  final Set<String> _fired = {};

  List<Cue> update(RunSession s, DateTime now) {
    final out = <Cue>[];
    final first = _index == null;

    if (!first && s.index != _index) {
      final prev = s.steps[_index!];
      final inTime = s.blocksInTime > _inTime;
      if (s.finished) {
        out.add(Cue(CueKind.missionDone, name: prev.name));
      } else {
        out.add(
          Cue(inTime ? CueKind.doneInTime : CueKind.doneLate, name: prev.name),
        );
      }
    }

    final changed = first || s.index != _index;
    _index = s.index;
    _inTime = s.blocksInTime;
    if (s.finished) return out;

    final step = s.current;
    final remaining = s.remaining(now);
    final started = now.difference(s.stepStartedAt);

    if (changed && started.inSeconds < 15) {
      out.add(
        Cue(
          step.icon == 'bus' ? CueKind.leaveHome : CueKind.blockStart,
          name: step.name,
          minutes: s.allowedMinutes,
        ),
      );
    }

    // Keys include the allowed minutes, so +5 re-arms the warnings.
    final key = '${s.index}:${s.allowedMinutes}';
    bool once(String what) => _fired.add('$key:$what');

    // On first look, mark what already passed so it is not replayed.
    if (first) {
      if (remaining.inSeconds <= 120) once('warn');
      if (remaining.inSeconds <= 0) once('up');
    }

    final secs = remaining.inSeconds;
    final warn = warnFor?.call(s.index) ?? true;
    if (warn &&
        s.allowedMinutes >= 4 &&
        secs <= 120 &&
        secs > 20 &&
        once('warn')) {
      out.add(Cue(CueKind.twoMinutesLeft, name: step.name, minutes: 2));
    }
    if (secs >= 1 && secs <= 3 && once('tick$secs')) {
      out.add(Cue(CueKind.tick, name: step.name));
    }
    if (secs <= 0 && once('up')) {
      out.add(Cue(CueKind.timeUp, name: step.name));
    }
    return out;
  }
}
