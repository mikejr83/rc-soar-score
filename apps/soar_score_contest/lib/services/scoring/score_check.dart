import 'time_entry.dart';

/// One thing the score check found for a pilot.
class ScoreFinding {
  const ScoreFinding({
    required this.rowKey,
    required this.pilot,
    required this.field,
    required this.message,
  });

  /// The row the finding belongs to (an assignment id value).
  final String rowKey;
  final String pilot;

  /// The F5J field to jump to, such as `time_flown`.
  final String field;
  final String message;
}

/// The result of a Score check. Reads the values only; nothing is changed.
class ScoreCheckResult {
  const ScoreCheckResult({required this.checked, required this.findings});

  /// How many pilots were looked at.
  final int checked;
  final List<ScoreFinding> findings;

  bool get isClean => findings.isEmpty;

  /// The findings of [rowKey], for the row's marker.
  Iterable<ScoreFinding> of(String rowKey) =>
      findings.where((f) => f.rowKey == rowKey);
}

/// What the check looks at for one pilot.
class CheckInput {
  const CheckInput({
    required this.rowKey,
    required this.pilot,
    required this.components,
    required this.entered,
  });

  final String rowKey;
  final String pilot;
  final Map<String, Object?> components;

  /// Whether the row has a saved score or typed values.
  final bool entered;
}

/// Looks for missing entries and values outside the expected range. The
/// ranges are the placeholders of the design (2:00 or more, 50 to 250 m)
/// until the configuration supplies them.
ScoreCheckResult runScoreCheck(
  Iterable<CheckInput> inputs, {
  double minSeconds = 120,
  int minHeight = 50,
  int maxHeight = 250,
}) {
  final findings = <ScoreFinding>[];
  var count = 0;
  for (final input in inputs) {
    count++;
    if (!input.entered) {
      findings.add(
        ScoreFinding(
          rowKey: input.rowKey,
          pilot: input.pilot,
          field: 'time_flown',
          message: 'Nothing entered yet.',
        ),
      );
      continue;
    }
    final c = input.components;
    final zeroed =
        c['motor_restart'] == true ||
        c['out_of_bounds'] == true ||
        c['no_altitude_recorded'] == true;
    if (zeroed) continue;
    final time = c['time_flown'];
    if (time is num && time < minSeconds) {
      findings.add(
        ScoreFinding(
          rowKey: input.rowKey,
          pilot: input.pilot,
          field: 'time_flown',
          message:
              '${TimeEntry.clock(time)} is under '
              '${TimeEntry.clock(minSeconds)}. Is it right?',
        ),
      );
    }
    final height = c['launch_height'];
    if (height is num && (height < minHeight || height > maxHeight)) {
      findings.add(
        ScoreFinding(
          rowKey: input.rowKey,
          pilot: input.pilot,
          field: 'launch_height',
          message:
              '${height.toInt()} m is outside $minHeight to $maxHeight m. '
              'Is it right?',
        ),
      );
    }
  }
  return ScoreCheckResult(checked: count, findings: findings);
}
