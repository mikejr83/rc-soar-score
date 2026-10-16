/// What the director typed in a time field, read as a flight time.
///
/// `630` is 6:30, `630.4` is 6:30.4 and `6:30` is accepted too. A comma works
/// as the decimal separator. The typed text is kept as it is, so a rejected
/// value never has to be typed again (`plan/ui/contest-administration/
/// official-scoring.md`).
class TimeEntry {
  const TimeEntry._({
    required this.text,
    this.seconds,
    this.display,
    this.error,
  });

  /// Reads [text] against [workingTimeSeconds]. A time equal to or above the
  /// working time is rejected, so 10:00 working time allows up to 9:59.
  factory TimeEntry.parse(String text, {required int workingTimeSeconds}) {
    final raw = text.trim().replaceAll(',', '.');
    if (raw.isEmpty) {
      return TimeEntry._(text: text);
    }
    final colon = RegExp(r'^(\d{1,3}):(\d{2})(?:\.(\d{1,3}))?$')
        .firstMatch(raw);
    final compact = RegExp(r'^(\d{1,5})(?:\.(\d{1,3}))?$').firstMatch(raw);
    final int minutes;
    final int secs;
    final String? fraction;
    if (colon != null) {
      minutes = int.parse(colon.group(1)!);
      secs = int.parse(colon.group(2)!);
      fraction = colon.group(3);
    } else if (compact != null) {
      final digits = int.parse(compact.group(1)!);
      minutes = digits ~/ 100;
      secs = digits % 100;
      fraction = compact.group(2);
    } else {
      return TimeEntry._(
        text: text,
        error: 'Type minutes and seconds, such as 630 for 6:30.',
      );
    }
    final shown =
        '$minutes:${secs.toString().padLeft(2, '0')}'
        '${fraction == null ? '' : '.$fraction'}';
    if (secs > 59) {
      return TimeEntry._(
        text: text,
        display: shown,
        error: 'Seconds go up to 59. $shown is not a time.',
      );
    }
    final double total =
        (minutes * 60 + secs) +
        (fraction == null ? 0.0 : double.parse('0.$fraction'));
    if (total >= workingTimeSeconds) {
      return TimeEntry._(
        text: text,
        display: shown,
        error:
            'Over the working time. The most is '
            '${_clock(workingTimeSeconds - 1)}.',
      );
    }
    return TimeEntry._(text: text, seconds: total, display: shown);
  }

  /// A time in seconds as minutes and seconds, `540` as `9:00`.
  static String clock(num seconds) {
    final whole = seconds.floor();
    final fraction = seconds - whole;
    final base = _clock(whole);
    if (fraction == 0) {
      return base;
    }
    final tenths = fraction.toStringAsFixed(3).substring(1);
    return base + tenths.replaceFirst(RegExp(r'0+$'), '');
  }

  static String _clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  /// The typed text.
  final String text;

  /// The time in seconds, when [text] is a valid time.
  final double? seconds;

  /// The parsed reading, such as `6:30.4`. Set for a rejected value too, when
  /// it could be read.
  final String? display;

  /// Why the value is rejected, or null.
  final String? error;

  bool get isEmpty => text.trim().isEmpty;
  bool get isValid => seconds != null;
}
