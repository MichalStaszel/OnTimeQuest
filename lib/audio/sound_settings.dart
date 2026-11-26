/// Who reads the voice lines. [none] means beeps only.
enum Narrator { none, male, female }

extension NarratorInfo on Narrator {
  String get label => switch (this) {
    Narrator.none => 'Bez lektora',
    Narrator.male => 'Pan Zegarek',
    Narrator.female => 'Pani Minutka',
  };

  String get blurb => switch (this) {
    Narrator.none => 'Tylko sygnały dźwiękowe.',
    Narrator.male => 'Komentator sportowy, trochę za bardzo przejęty.',
    Narrator.female => 'Wesoła i szybka, zawsze po Twojej stronie.',
  };
}

/// Sound preferences, saved locally.
class SoundSettings {
  const SoundSettings({this.beeps = true, this.narrator = Narrator.female});

  final bool beeps;
  final Narrator narrator;

  bool get silent => !beeps && narrator == Narrator.none;

  SoundSettings copyWith({bool? beeps, Narrator? narrator}) => SoundSettings(
    beeps: beeps ?? this.beeps,
    narrator: narrator ?? this.narrator,
  );

  Map<String, dynamic> toJson() => {'beeps': beeps, 'narrator': narrator.name};

  factory SoundSettings.fromJson(Map<String, dynamic> j) => SoundSettings(
    beeps: j['beeps'] as bool? ?? true,
    narrator: Narrator.values.asNameMap()[j['narrator']] ?? Narrator.female,
  );
}
