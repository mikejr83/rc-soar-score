import 'package:flutter/foundation.dart';

import 'score_entry_settings.dart';
import 'time_entry.dart';

/// A problem that keeps a row from saving, tied to the field it belongs to.
class RowProblem {
  const RowProblem(this.field, this.message);

  /// The F5J field id, such as `time_flown`.
  final String field;
  final String message;
}

/// What the director has typed for one pilot's flight, and the rules that
/// follow from it (`plan/ui/contest-administration/briefs/scoring.md`).
///
/// Holds the raw text of each field, so a rejected value stays on screen
/// until it is corrected. [components] gives the request body of the save.
class ScoreRowDraft extends ChangeNotifier {
  ScoreRowDraft({required this.settings, Map<String, Object?> saved = const {}})
    : _baseline = Map.of(saved) {
    _load(saved);
  }

  final ScoreEntrySettings settings;
  Map<String, Object?> _baseline;

  String timeText = '';
  String heightText = '';
  String? landing;
  bool lateLanding = false;
  bool motorRestart = false;
  bool outOfBounds = false;
  bool noAltitude = false;
  String penaltyText = '';
  String cumulativePenaltyText = '';

  /// True once the director confirmed that an empty or zeroing row is a zero.
  bool zeroConfirmed = false;

  void _load(Map<String, Object?> saved) {
    final time = saved['time_flown'];
    timeText = time is num ? TimeEntry.clock(time) : '';
    final height = saved['launch_height'];
    heightText = height is num ? '${height.toInt()}' : '';
    landing = saved['landing'] as String?;
    lateLanding = saved['late_landing'] == true;
    motorRestart = saved['motor_restart'] == true;
    outOfBounds = saved['out_of_bounds'] == true;
    noAltitude = saved['no_altitude_recorded'] == true;
    final penalty = saved['flight_penalty'];
    penaltyText = penalty is num && penalty > 0 ? '${penalty.toInt()}' : '';
    final cumulative = saved['cumulative_penalty'];
    cumulativePenaltyText = cumulative is num ? '${cumulative.toInt()}' : '';
    zeroConfirmed = false;
  }

  /// Replaces the draft with [saved], after a save or a reload.
  void resetTo(Map<String, Object?> saved) {
    _baseline = Map.of(saved);
    _load(saved);
    notifyListeners();
  }

  /// Keeps what was typed and makes [saved] the baseline it is compared to.
  void rebase(Map<String, Object?> saved) {
    _baseline = Map.of(saved);
    notifyListeners();
  }

  // Parsed values.

  TimeEntry get time => TimeEntry.parse(
    timeText,
    workingTimeSeconds: settings.workingTimeSeconds,
  );

  /// The launch height in metres, or null when empty or not a whole number.
  int? get height => int.tryParse(heightText.trim());

  bool get heightMalformed =>
      heightText.trim().isNotEmpty && int.tryParse(heightText.trim()) == null;

  int? get penalty => int.tryParse(penaltyText.trim());

  bool get penaltyMalformed =>
      penaltyText.trim().isNotEmpty && (penalty == null || penalty! < 0);

  /// The cumulative penalty: `null` when the field is empty (never applied),
  /// or the whole number typed, including `0` (a removal).
  int? get cumulativePenalty =>
      cumulativePenaltyText.trim().isEmpty ? null : int.tryParse(cumulativePenaltyText.trim());

  bool get cumulativePenaltyMalformed =>
      cumulativePenaltyText.trim().isNotEmpty &&
      (cumulativePenalty == null || cumulativePenalty! < 0);

  // Rules.

  /// Motor restart, out of bounds or no altitude recorded: the flight scores
  /// zero and time, height and landing are not entered.
  bool get zeroing => motorRestart || outOfBounds || noAltitude;

  /// Why time and height are off, or null when they can be typed.
  String? get measurementsOffReason {
    if (noAltitude) return 'Scores 0: no altitude recorded';
    if (motorRestart) return 'Scores 0: motor restart';
    if (outOfBounds) return 'Scores 0: out of bounds';
    return null;
  }

  String? get landingOffReason {
    if (measurementsOffReason != null) return measurementsOffReason;
    if (lateLanding) return 'Late landing: the landing bonus is not given';
    return null;
  }

  String? get lateLandingOffReason {
    if (noAltitude) return 'Off while no altitude is recorded';
    if (outOfBounds) return 'Off while out of bounds is on';
    return null;
  }

  String? get motorRestartOffReason {
    if (noAltitude) return 'Off while no altitude is recorded';
    if (outOfBounds) return 'Off while out of bounds is on';
    return null;
  }

  String? get outOfBoundsOffReason {
    if (noAltitude) return 'Off while no altitude is recorded';
    if (motorRestart) return 'Off while motor restart is on';
    if (lateLanding) return 'Off while late landing is on';
    return null;
  }

  String? get noAltitudeOffReason {
    if (motorRestart) return 'Off while motor restart is on';
    if (outOfBounds) return 'Off while out of bounds is on';
    return null;
  }

  // Changes.

  void _changed() {
    zeroConfirmed = false;
    notifyListeners();
  }

  void setTime(String value) {
    timeText = value;
    _changed();
  }

  void setHeight(String value) {
    heightText = value;
    _changed();
  }

  void setLanding(String? key) {
    landing = key;
    _changed();
  }

  void setPenalty(String value) {
    penaltyText = value;
    _changed();
  }

  void setCumulativePenalty(String value) {
    cumulativePenaltyText = value;
    _changed();
  }

  void setLateLanding(bool on) {
    lateLanding = on;
    if (on) landing = null;
    _changed();
  }

  void setMotorRestart(bool on) {
    motorRestart = on;
    if (on) _zeroMeasurements();
    _changed();
  }

  void setOutOfBounds(bool on) {
    outOfBounds = on;
    if (on) _zeroMeasurements();
    _changed();
  }

  void setNoAltitude(bool on) {
    noAltitude = on;
    if (on) _zeroMeasurements();
    _changed();
  }

  void confirmZero() {
    zeroConfirmed = true;
    notifyListeners();
  }

  void _zeroMeasurements() {
    timeText = '';
    heightText = '';
    landing = null;
    lateLanding = false;
  }

  // State.

  /// Nothing entered at all: no values, no status, no penalty.
  bool get isBlank =>
      timeText.trim().isEmpty &&
      heightText.trim().isEmpty &&
      landing == null &&
      !lateLanding &&
      !zeroing &&
      penaltyText.trim().isEmpty &&
      cumulativePenaltyText.trim().isEmpty;

  /// Whether saving would record a zero that the director must acknowledge.
  bool get needsZeroConfirmation => isBlank || zeroing;

  /// Whether time, height and landing hold something; a partly entered row.
  bool get isPartial =>
      !isBlank &&
      !zeroing &&
      (timeText.trim().isEmpty || (height == null && !heightMalformed));

  /// What the save would send. Fields that are off or empty are left out.
  Map<String, Object?> get components {
    final out = <String, Object?>{};
    if (noAltitude) {
      out['no_altitude_recorded'] = true;
    } else if (motorRestart) {
      out['motor_restart'] = true;
    } else if (outOfBounds) {
      out['out_of_bounds'] = true;
    } else {
      final seconds = time.seconds;
      if (seconds != null) {
        out['time_flown'] = seconds == seconds.roundToDouble()
            ? seconds.toInt()
            : seconds;
      }
      final metres = height;
      if (metres != null) out['launch_height'] = metres;
      if (landing != null && !lateLanding) out['landing'] = landing;
      if (lateLanding) out['late_landing'] = true;
    }
    final points = penalty;
    if (points != null && points > 0) out['flight_penalty'] = points;
    final cumulative = cumulativePenalty;
    if (cumulative != null) {
      // Unlike the flight penalty, 0 is a real value: an applied penalty
      // that was removed. It is stored, not dropped.
      out['cumulative_penalty'] = cumulative;
    }
    return out;
  }

  /// Whether the typed values differ from what is saved.
  bool get isDirty => !_same(components, _baseline);

  static bool _same(Map<String, Object?> a, Map<String, Object?> b) {
    Map<String, Object?> clean(Map<String, Object?> m) => {
      for (final e in m.entries)
        if (e.value != null &&
            e.value != false &&
            (e.value != 0 || e.key == 'cumulative_penalty'))
          e.key: e.value is num ? (e.value! as num).toDouble() : e.value,
    };
    final x = clean(a);
    final y = clean(b);
    if (x.length != y.length) return false;
    for (final key in x.keys) {
      if (x[key] != y[key]) return false;
    }
    return true;
  }

  /// Why this row cannot be saved yet. Empty when it can.
  List<RowProblem> get problems {
    final out = <RowProblem>[];
    if (!zeroing) {
      final t = time;
      if (t.error != null) out.add(RowProblem('time_flown', t.error!));
      if (heightMalformed) {
        out.add(
          const RowProblem('launch_height', 'Whole metres only, no decimals.'),
        );
      } else if (height != null && height! <= 0) {
        out.add(
          const RowProblem(
            'launch_height',
            '0 m is not a launch height. Turn on No altitude recorded '
                'instead.',
          ),
        );
      }
      if (t.isValid && height == null && !heightMalformed) {
        out.add(
          const RowProblem(
            'launch_height',
            'Launch height is needed with a time.',
          ),
        );
      }
      if (height != null && height! > 0 && timeText.trim().isEmpty) {
        out.add(
          const RowProblem('time_flown', 'Time flown is needed with a height.'),
        );
      }
    }
    if (penaltyMalformed) {
      out.add(
        const RowProblem(
          'flight_penalty',
          'A whole number of points, 0 or more.',
        ),
      );
    }
    if (cumulativePenaltyMalformed) {
      out.add(
        const RowProblem(
          'cumulative_penalty',
          'A whole number of points, 0 or more.',
        ),
      );
    }
    return out;
  }

  /// Whether the launch height asks "Is this correct?".
  bool get heightUnusual => height != null && height! > settings.unusualHeight;

  /// Whether the height is 0, which saves as No altitude recorded.
  bool get heightZero => height != null && height! == 0;
}
