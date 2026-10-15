/// Detik -> menit (dibulatkan ke bawah) untuk tampilan "5 / 10 min".
int toMinutes(int seconds) => seconds ~/ 60;

String formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  if (m < 60) return '$m min';
  final h = m ~/ 60;
  final rest = m % 60;
  return rest == 0 ? '$h h' : '$h h $rest min';
}

const _weekdays = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
];

String weekdayName(DateTime d) => _weekdays[d.weekday - 1];

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';
