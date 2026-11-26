import '../logic/format.dart';
import '../models/run_session.dart';

/// What the ongoing "mission in progress" notification shows. Pure data,
/// built from the session, so it can be tested without Android.
class MissionNotice {
  const MissionNotice({
    required this.title,
    required this.body,
    required this.progress,
    required this.endsAt,
    required this.over,
    required this.allowPlusFive,
    required this.payload,
  });

  final String title;
  final String body;

  /// 0..[maxProgress], how much of the current block's time is used.
  final int progress;
  static const maxProgress = 1000;

  /// When the block's time runs out; the notification counts down to it.
  final DateTime endsAt;
  final bool over;
  final bool allowPlusFive;

  /// Identifies the block, so a tap on an old notification is ignored.
  final String payload;
}

/// A heads-up reminder scheduled for a moment in the current block.
class Prompt {
  const Prompt(this.id, this.at, this.title, this.body);

  final int id;
  final DateTime at;
  final String title;
  final String body;
}

String stepPayload(RunSession s) => '${s.missionId}#${s.index}';

MissionNotice missionNotice(RunSession s, DateTime now) {
  final total = s.allowedMinutes * 60;
  final elapsed = now.difference(s.stepStartedAt).inSeconds.clamp(0, 1 << 30);
  final over = elapsed >= total;
  final next = s.next;
  final arrival = hhmm(s.projectedArrival(now));
  final goal = hhmm(s.arriveAt);
  final lines = <String>[
    if (over) 'Czas etapu minął. Gotowe albo +5?',
    next == null ? 'Potem meta!' : 'Dalej: ${next.name}, ${next.minutes} min',
    'Na miejscu ok. $arrival (cel $goal)',
  ];
  return MissionNotice(
    title: '${s.current.name} · etap ${s.index + 1} z ${s.steps.length}',
    body: lines.join(' · '),
    progress: total == 0
        ? MissionNotice.maxProgress
        : (elapsed * MissionNotice.maxProgress ~/ total).clamp(
            0,
            MissionNotice.maxProgress,
          ),
    endsAt: s.stepEndsAt,
    over: over,
    allowPlusFive: s.current.allowPlusFive,
    payload: stepPayload(s),
  );
}

const promptWarnId = 10;
const promptUpId = 11;

/// Reminders for the current block that are still in the future: two
/// minutes before the end (for blocks of 4+ minutes) and when it ends.
List<Prompt> promptsFor(RunSession s, DateTime now, {bool warn = true}) {
  if (s.finished) return const [];
  final end = s.stepEndsAt;
  final name = s.current.name;
  final next = s.next;
  final then = next == null ? 'Potem meta!' : 'Potem: ${next.name}.';
  return [
    if (warn && s.allowedMinutes >= 4)
      Prompt(
        promptWarnId,
        end.subtract(const Duration(minutes: 2)),
        'Za 2 min koniec: $name',
        'Kończ powoli, inaczej się spóźnisz. $then',
      ),
    Prompt(
      promptUpId,
      end,
      'Czas minął: $name',
      next == null
          ? 'Kliknij Gotowe i ruszaj. Jeszcze zdążysz.'
          : 'Kliknij Gotowe i lecimy: ${next.name}. Jeszcze zdążysz.',
    ),
  ].where((p) => p.at.isAfter(now)).toList();
}

/// A button pressed on a notification while the app was not listening.
/// Saved and applied later in the order they happened.
class QueuedAction {
  const QueuedAction(this.action, this.payload, this.at);

  /// 'done' or 'plus5'.
  final String action;
  final String payload;
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'action': action,
    'payload': payload,
    'at': at.toIso8601String(),
  };

  factory QueuedAction.fromJson(Map<String, dynamic> j) => QueuedAction(
    j['action'] as String,
    j['payload'] as String,
    DateTime.parse(j['at'] as String),
  );
}
