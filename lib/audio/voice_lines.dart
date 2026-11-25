import 'dart:math' as math;

import 'cues.dart';
import 'sound_settings.dart';

/// One thing the narrator can say. [id] names a pre-recorded clip:
/// `assets/voice/<narrator>/<id>.mp3`. When that file exists it is played,
/// otherwise the text is read by the phone's speech engine.
class VoiceLine {
  const VoiceLine(this.id, this.text);

  final String id;

  /// May contain {name} (block name) and {min} (minutes).
  final String text;

  /// Lines with a placeholder can only use a clip when it does not depend
  /// on the value, so they are read by text-to-speech.
  bool get hasPlaceholders => text.contains('{');

  String fill(Cue c) => text
      .replaceAll('{name}', c.name)
      .replaceAll('{min}', minutesSpoken(c.minutes));
}

/// "1 minuta", "3 minuty", "25 minut".
String minutesSpoken(int n) {
  if (n == 1) return '1 minuta';
  final last = n % 10, lastTwo = n % 100;
  if (last >= 2 && last <= 4 && (lastTwo < 12 || lastTwo > 14)) {
    return '$n minuty';
  }
  return '$n minut';
}

/// The scripts. Tone rules: funny, warm, never shaming. Late is "we can
/// still make it", not "you failed".
const Map<Narrator, Map<CueKind, List<VoiceLine>>> voiceLines = {
  Narrator.male: {
    CueKind.blockStart: [
      VoiceLine('m_start_1', '{name}. {min}. Zegar rusza, panie i panowie!'),
      VoiceLine('m_start_2', '{name}. Masz {min}. Tiko już trzyma stoper.'),
      VoiceLine('m_start_3', 'Kolejna konkurencja: {name}. {min} na liczniku!'),
    ],
    CueKind.leaveHome: [
      VoiceLine(
        'm_leave_1',
        'Wychodzimy! Klucze, telefon, portfel. Reszta to już formalność.',
      ),
      VoiceLine('m_leave_2', 'Czas na wyjście. Buty na nogi, drzwi za sobą!'),
    ],
    CueKind.twoMinutesLeft: [
      VoiceLine(
        'm_warn_1',
        'Skończ ten blok w dwie minuty, inaczej się spóźnisz. '
            'Bez paniki, tylko sprint!',
      ),
      VoiceLine(
        'm_warn_2',
        'Dwie minuty do końca! Zawodnik wchodzi na ostatnią prostą!',
      ),
    ],
    CueKind.timeUp: [
      VoiceLine(
        'm_up_1',
        'Czas etapu minął. Spokojnie, kliknij Gotowe albo weź plus pięć.',
      ),
      VoiceLine('m_up_2', 'Gwizdek! Ale mecz trwa, jeszcze zdążymy.'),
    ],
    CueKind.doneInTime: [
      VoiceLine('m_done_1', 'Gotowe! Jabłko dla Tiko!'),
      VoiceLine('m_done_2', 'Co za tempo! Jabłko leci do Tiko.'),
    ],
    CueKind.doneLate: [
      VoiceLine('m_late_1', 'Zaliczone. Lecimy dalej!'),
      VoiceLine('m_late_2', 'Jest! Następny etap, nie oglądamy się.'),
    ],
    CueKind.missionDone: [
      VoiceLine('m_finish_1', 'Meta! Teraz tylko dotrzyj na miejsce.'),
    ],
  },
  Narrator.female: {
    CueKind.blockStart: [
      VoiceLine('f_start_1', '{name}! {min}, dasz radę, ja tu poczekam.'),
      VoiceLine('f_start_2', 'Czas na: {name}. {min}, start!'),
      VoiceLine('f_start_3', '{name}. {min}. Tiko już kibicuje!'),
    ],
    CueKind.leaveHome: [
      VoiceLine('f_leave_1', 'Wychodzimy! Sprawdź klucze i telefon.'),
      VoiceLine('f_leave_2', 'Pora ruszać! Świat na Ciebie czeka.'),
    ],
    CueKind.twoMinutesLeft: [
      VoiceLine(
        'f_warn_1',
        'Psst. Skończ ten blok w dwie minutki, inaczej się spóźnisz.',
      ),
      VoiceLine('f_warn_2', 'Dwie minutki! Tiko już przebiera nóżkami.'),
    ],
    CueKind.timeUp: [
      VoiceLine(
        'f_up_1',
        'Ups, czas minął. Nic się nie stało, jeszcze zdążymy.',
      ),
      VoiceLine('f_up_2', 'Czas etapu minął. Gotowe, albo plus pięć?'),
    ],
    CueKind.doneInTime: [
      VoiceLine('f_done_1', 'Brawo! Tiko chrupie jabłko.'),
      VoiceLine('f_done_2', 'Super! Jabłko dla Tiko!'),
    ],
    CueKind.doneLate: [
      VoiceLine('f_late_1', 'Zrobione! Idziemy dalej.'),
      VoiceLine('f_late_2', 'Jest! Następny etap.'),
    ],
    CueKind.missionDone: [
      VoiceLine('f_finish_1', 'Wszystko zrobione. W drogę!'),
    ],
  },
};

/// Picks a line for a cue, or null when the narrator has nothing to say
/// (ticks are beep-only).
VoiceLine? pickLine(Narrator n, CueKind kind, [math.Random? rng]) {
  final list = voiceLines[n]?[kind];
  if (list == null || list.isEmpty) return null;
  return list[(rng ?? math.Random()).nextInt(list.length)];
}
