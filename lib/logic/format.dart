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
