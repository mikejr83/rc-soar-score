import 'package:soar_score_core/soar_score_core.dart';

import '../../matrix/draw_form_check.dart';

/// Small text helpers for the next-step copy.
abstract final class NextStepText {
  /// "1 pilot", "2 pilots".
  static String count(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

  /// "A" for group number 1, "B" for 2.
  static String group(int number) => DrawFormCheck.groupLetter(number - 1);

  /// [text] with its first letter in lower case.
  static String lowerFirst(String text) =>
      text.isEmpty ? text : text[0].toLowerCase() + text.substring(1);

  /// `Sun Oct 18, 16:40` for [utc] in [zoneId]. An unknown zone falls back to
  /// UTC rather than failing the card.
  static String when(DateTime utc, String zoneId) {
    final id = ContestTimeZones.isValid(zoneId) ? zoneId : ContestTimeZones.utc;
    final t = ContestTime.inZone(utc, id);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String two(int n) => n.toString().padLeft(2, '0');
    return '${days[t.weekday - 1]} ${months[t.month - 1]} ${t.day}, '
        '${two(t.hour)}:${two(t.minute)}';
  }
}
