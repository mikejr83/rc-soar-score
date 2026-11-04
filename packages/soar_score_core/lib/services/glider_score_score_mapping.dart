import '../enums/landing_input_unit.dart';
import '../models/imports/draw_import_draft.dart';
import '../models/imports/restore_plan.dart';
import '../models/landing/landing_table_with_results.dart';
import '../models/landing/system_landing_tables.dart';

/// The class-specific part of the score mapping, behind the [ClassMapper]
/// registry. The restore mapper knows nothing about F5J: it asks the score
/// mapper of the competition's class for the landing table and for the
/// values of each scored flight.
abstract class ClassScoreMapper {
  const ClassScoreMapper();

  /// The landing table the competition used and how each landing value
  /// resolves in Soar Score.
  ///
  /// [tableRows] are the `LndgPoints` rows of the competition's table
  /// (`Distance` is the value a scorer picks, `Points` what it awards);
  /// [observed] are the non-zero landing values found in its scored flights.
  LandingSelection selectLanding({
    required int? sourceTableNo,
    required String? sourceTableName,
    required List<({int value, num points})> tableRows,
    required Set<int> observed,
  });

  /// One scored flight's values, or the reason it cannot be represented.
  FlightValues mapFlight(FlightDraft flight, ScoreMappingContext context);
}

/// What a flight is mapped against.
class ScoreMappingContext {
  const ScoreMappingContext({
    required this.restartOption,
    required this.workingTimeSeconds,
    required this.landing,
  });

  /// `F5JMotorRestartOption`: 0 not allowed, 1 and 2 allowed (the flag zeroes
  /// the flight); null in files that predate it.
  final int? restartOption;
  final num workingTimeSeconds;
  final LandingSelection landing;
}

/// The mapped values of one scored flight.
class FlightValues {
  const FlightValues({
    required this.kind,
    required this.components,
    required this.rawComponents,
    this.warnings = const [],
    this.refusal,
    this.refusalDetail,
  });

  final RestoredFlightKind kind;
  final Map<String, Object?> components;
  final Map<String, Object?> rawComponents;
  final List<RestoreWarning> warnings;

  /// A [FlightRefusal] code when the flight cannot be represented.
  final String? refusal;
  final String? refusalDetail;

  bool get isRefused => refusal != null;
}

/// F5J: duration, launch height, landing, penalty and motor restart.
///
/// Mapping rules: ADR 0006 amendment 2 and mapping plan 5.5.4.
class F5jScoreMapper extends ClassScoreMapper {
  const F5jScoreMapper();

  @override
  LandingSelection selectLanding({
    required int? sourceTableNo,
    required String? sourceTableName,
    required List<({int value, num points})> tableRows,
    required Set<int> observed,
  }) {
    if (observed.isEmpty) {
      return LandingSelection(
        match: LandingMatch.none,
        systemTable: _standard,
        sourceTableNo: sourceTableNo,
      );
    }
    // What GliderScore awarded for each landing value. A file without the
    // table is read as GliderScore's default "F5J Enter Points": the value is
    // the points.
    final pointsOf = <int, num>{for (final r in tableRows) r.value: r.points};
    num? awarded(int value) => tableRows.isEmpty ? value : pointsOf[value];

    final candidates = <_Candidate>[
      _Candidate.system(_standard, SystemLandingTables.f5jStandard),
      _Candidate.system(_distance, SystemLandingTables.f5jDistance),
      if (tableRows.isNotEmpty) _Candidate.rebuilt(tableRows),
    ];

    _Candidate? best;
    var bestResolved = -1;
    Map<int, String> bestKeys = const {};
    for (final c in candidates) {
      final keys = <int, String>{};
      for (final value in observed) {
        final points = awarded(value);
        final key = points == null ? null : c.keyFor(value, points);
        if (key != null) {
          keys[value] = key;
        }
      }
      if (keys.length > bestResolved) {
        best = c;
        bestResolved = keys.length;
        bestKeys = keys;
      }
      if (keys.length == observed.length) {
        break;
      }
    }
    final chosen = best!;
    final unresolved = {
      for (final v in observed)
        if (!bestKeys.containsKey(v)) v,
    };
    final complete = unresolved.isEmpty;
    return LandingSelection(
      match: !complete
          ? LandingMatch.partial
          : chosen.rebuilt
          ? LandingMatch.reconstructed
          : LandingMatch.system,
      systemTable: chosen.rebuilt ? null : chosen.name,
      reconstructedName: chosen.rebuilt
          ? (sourceTableName ?? 'GliderScore landing table $sourceTableNo')
          : null,
      entries: chosen.rebuilt ? chosen.entries : const [],
      entryKeys: bestKeys,
      unresolved: unresolved,
      sourceTableNo: sourceTableNo,
    );
  }

  static const _standard = 'f5jStandard';
  static const _distance = 'f5jDistance';

  @override
  FlightValues mapFlight(FlightDraft flight, ScoreMappingContext context) {
    final raw = <String, Object?>{
      'time_1_mins': flight.time1Mins,
      'time_1_secs': flight.time1Secs,
      'time_2_mins': flight.time2Mins,
      'time_2_secs': flight.time2Secs,
      'flight_score_deduction': flight.flightScoreDeduction,
      'landing': flight.landing,
      'penalty': flight.penalty,
      'motor_restarted': flight.motorRestarted,
      'helper': flight.helper,
      'laps': flight.laps,
      'landing_over_75m': flight.landingOver75m,
      'draw_frequency': flight.drawFrequency,
      'scores_checked': flight.scoresChecked,
      'original_round_no': flight.originalRoundNo,
      'raw_score': flight.rawScore,
      'normalised_score': flight.normalisedScore,
    }..removeWhere((_, v) => v == null);

    FlightValues refused(String code, [String? detail]) => FlightValues(
      kind: RestoredFlightKind.entered,
      components: const {},
      rawComponents: raw,
      refusal: code,
      refusalDetail: detail,
    );

    // The packed M:SS value: 1458 is 14 minutes 58 seconds.
    final packed = flight.time1Mins ?? 0;
    if (packed < 0 || packed != packed.truncate() || packed % 100 >= 60) {
      return refused(FlightRefusal.timeInvalid, '$packed');
    }
    final seconds = (packed ~/ 100) * 60 + (packed % 100).toInt();
    final height = flight.flightScoreDeduction ?? 0;
    if (height < 0 || height != height.truncate()) {
      return refused(FlightRefusal.heightNotWhole, '$height');
    }
    final penalty = flight.penalty ?? 0;
    if (penalty < 0 || penalty != penalty.truncate()) {
      return refused(FlightRefusal.penaltyNotWhole, '$penalty');
    }
    final landing = (flight.landing ?? 0).toInt();
    final restartFlag = (flight.motorRestarted ?? 0) != 0;
    final restartZero =
        restartFlag &&
        (context.restartOption == 1 || context.restartOption == 2);

    if ((seconds > 0) != (height > 0)) {
      return refused(
        FlightRefusal.timeHeightMismatch,
        'time ${seconds}s height $height',
      );
    }
    if (!restartZero && seconds >= context.workingTimeSeconds) {
      return refused(FlightRefusal.timeOverWorkingTime, '${seconds}s');
    }

    final warnings = <RestoreWarning>[];
    final components = <String, Object?>{};
    final keys = context.landing.entryKeys;
    if (seconds > 0) {
      components['time_flown'] = seconds;
      components['launch_height'] = height.toInt();
    }
    if (landing != 0) {
      final key = keys[landing];
      if (key == null) {
        warnings.add(
          RestoreWarning(
            RestoreWarning.landingUnresolved,
            round: flight.roundNo,
            group: flight.groupNo,
            sourcePilotNo: flight.sourcePilotNo,
            detail: '$landing',
          ),
        );
      } else {
        components['landing'] = key;
      }
    }
    if (penalty > 0) {
      components['flight_penalty'] = penalty.toInt();
    }

    if (restartZero) {
      components['motor_restart'] = true;
      return FlightValues(
        kind: RestoredFlightKind.restartZero,
        components: components,
        rawComponents: raw,
        warnings: warnings,
      );
    }
    if (restartFlag) {
      warnings.add(
        RestoreWarning(
          RestoreWarning.motorRestartKept,
          round: flight.roundNo,
          group: flight.groupNo,
          sourcePilotNo: flight.sourcePilotNo,
          detail: 'option ${context.restartOption}',
        ),
      );
    }
    final allZero = seconds == 0 && landing == 0 && penalty == 0;
    if (allZero && !restartFlag) {
      warnings.add(
        RestoreWarning(
          RestoreWarning.allZeroFlight,
          round: flight.roundNo,
          group: flight.groupNo,
          sourcePilotNo: flight.sourcePilotNo,
        ),
      );
    }
    return FlightValues(
      kind: restartFlag
          ? RestoredFlightKind.restartKept
          : allZero
          ? RestoredFlightKind.allZero
          : RestoredFlightKind.entered,
      components: components,
      rawComponents: raw,
      warnings: warnings,
    );
  }
}

/// A landing table the observed values are tried against.
class _Candidate {
  _Candidate._(this.name, this.rebuilt, this.entries, this._table);

  /// A table the system ships.
  factory _Candidate.system(String name, LandingTableWithResults table) =>
      _Candidate._(name, false, const [], table);

  /// The competition's own table, rebuilt from the file: one entry per
  /// landing value.
  factory _Candidate.rebuilt(List<({int value, num points})> rows) {
    final entries = [
      for (final r in rows)
        LandingEntryDraft(
          entryKey: 'gs_${r.value}',
          label: '${r.value}',
          points: r.points.round(),
        ),
    ];
    return _Candidate._('rebuilt', true, entries, null);
  }

  final String name;
  final bool rebuilt;
  final List<LandingEntryDraft> entries;
  final LandingTableWithResults? _table;

  /// The entry that stands for the landing [value] awarding [points].
  ///
  /// A table the scorer picks points from (`LandingInputUnit.points`) fits a
  /// GliderScore table whose values are the points; a table the scorer picks
  /// a distance from (`meters`) fits one whose values are metres. Either way
  /// the entry must award the points GliderScore awarded, and be the only one
  /// that does. The rebuilt table has an entry for every value.
  String? keyFor(int value, num points) {
    final table = _table;
    if (table == null) {
      return 'gs_$value';
    }
    final keys = <String>[
      for (final r in table.results)
        if (r.pointValue == points &&
            (table.table.inputUnit == LandingInputUnit.points
                ? points == value
                : r.displayValue == '${value}m'))
          r.entryKey,
    ];
    return keys.length == 1 ? keys.single : null;
  }
}
