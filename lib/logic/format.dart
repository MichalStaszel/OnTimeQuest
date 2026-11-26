String two(int n) => n.toString().padLeft(2, '0');

/// 09:55
String hhmm(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

/// 40 min / 2 h 05
String durationLabel(int minutes) {
  if (minutes < 60) return '$minutes min';
  return '${minutes ~/ 60} h ${two(minutes % 60)}';
}

/// 24:59 for a countdown; negative values are shown as +01:12 (overtime).
String countdownLabel(Duration d) {
  final over = d.isNegative;
  final s = d.inSeconds.abs();
  final text = s >= 3600
      ? '${s ~/ 3600}:${two((s % 3600) ~/ 60)}:${two(s % 60)}'
      : '${two(s ~/ 60)}:${two(s % 60)}';
  return over ? '+$text' : text;
}

const _weekdays = [
  'poniedziałek',
  'wtorek',
  'środa',
  'czwartek',
  'piątek',
  'sobota',
  'niedziela',
];
const _monthsGen = [
  'stycznia',
  'lutego',
  'marca',
  'kwietnia',
  'maja',
  'czerwca',
  'lipca',
  'sierpnia',
  'września',
  'października',
  'listopada',
  'grudnia',
];

/// "Środa, 25 listopada"
String longDate(DateTime d) {
  final w = _weekdays[d.weekday - 1];
  return '${w[0].toUpperCase()}${w.substring(1)}, ${d.day} ${_monthsGen[d.month - 1]}';
}

/// "dziś" / "jutro" / "pt 28.11"
String dayLabel(DateTime day, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(day.year, day.month, day.day);
  final diff = d.difference(today).inHours ~/ 24;
  if (diff == 0) return 'dziś';
  if (diff == 1) return 'jutro';
  if (diff == -1) return 'wczoraj';
  const short = ['pn', 'wt', 'śr', 'cz', 'pt', 'so', 'nd'];
  return '${short[d.weekday - 1]} ${d.day}.${two(d.month)}';
}

/// "za 35 min" / "za 2 h 10" / "teraz" / "5 min temu"
String relative(DateTime t, DateTime now) {
  final m = (t.difference(now).inSeconds / 60).round();
  if (m.abs() < 1) return 'teraz';
  if (m > 0) return 'za ${durationLabel(m)}';
  return '${durationLabel(-m)} temu';
}

/// "1 blok" / "3 bloki" / "7 bloków"
String blocksWord(int n) {
  if (n == 1) return '1 blok';
  final last = n % 10, lastTwo = n % 100;
  if (last >= 2 && last <= 4 && (lastTwo < 12 || lastTwo > 14)) {
    return '$n bloki';
  }
  return '$n bloków';
}
