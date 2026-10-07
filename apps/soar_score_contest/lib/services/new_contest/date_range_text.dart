import 'package:intl/intl.dart';

/// [start] to [end] as compact text: `Nov 14, 2026`, `Sep 5–6, 2026`,
/// `Sep 30 – Oct 1, 2026` or `Dec 31, 2026 – Jan 1, 2027`.
String dateRangeText(DateTime start, DateTime end) {
  final day = DateFormat.d('en_US');
  final monthDay = DateFormat.MMMd('en_US');
  final full = DateFormat.yMMMd('en_US');
  if (start.year != end.year) {
    return '${full.format(start)} – ${full.format(end)}';
  }
  if (start.month != end.month) {
    return '${monthDay.format(start)} – ${full.format(end)}';
  }
  if (start.day != end.day) {
    return '${monthDay.format(start)}–${day.format(end)}, ${end.year}';
  }
  return full.format(start);
}
