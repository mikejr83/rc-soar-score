import 'package:equatable/equatable.dart';

import '../../enums/draw_mode.dart';
import '../../enums/group_score_mode.dart';
import '../../enums/lane_mode.dart';
import '../../enums/public_update_mode.dart';
import '../../enums/rounding_mode.dart';

/// The core contest options, resolved against the platform defaults.
///
/// Mirrors the table in `plan/data-model/contest-options.md`, including the
/// dependencies the service enforces. Unknown keys are ignored here so a
/// newer configuration still reads.
class CoreOptions extends Equatable {
  CoreOptions({
    this.teamsEnabled = false,
    this.teamPilotCount,
    this.teamProtection = false,
    this.rolesEnabled = false,
    this.drawMode = DrawMode.standardManOnMan,
    this.preliminaryRounds,
    this.laneMode = LaneMode.none,
    this.groupScoreMode = GroupScoreMode.normalized,
    this.roundingMode = RoundingMode.round,
    this.decimalPlaces = 1,
    List<int> dropAfterRounds = const [],
    this.tiebreakerEnabled = false,
    this.classesEnabled = false,
    this.modelsEnabled = false,
    this.participantNumbersEnabled = false,
    this.reviewRequestsEnabled = true,
    this.publicUpdateMode = PublicUpdateMode.roundCompletion,
    this.intendedTotalRounds,
  }) : dropAfterRounds = List.unmodifiable(dropAfterRounds) {
    if (teamsEnabled) {
      if (teamPilotCount == null) {
        throw ArgumentError('team_pilot_count is required when teams_enabled');
      }
    } else if (teamPilotCount != null || teamProtection) {
      throw ArgumentError(
        'team_pilot_count and team_protection need teams_enabled',
      );
    }
    if (teamPilotCount != null && teamPilotCount! < 1) {
      throw ArgumentError.value(
        teamPilotCount,
        'teamPilotCount',
        'must be 1 or more',
      );
    }
    final seeded = drawMode == DrawMode.seededManOnMan;
    if (!seeded && (preliminaryRounds != null || intendedTotalRounds != null)) {
      throw ArgumentError(
        'preliminary_rounds and intended_total_rounds need SeededManOnMan',
      );
    }
    for (final (name, value) in [
      ('preliminaryRounds', preliminaryRounds),
      ('intendedTotalRounds', intendedTotalRounds),
    ]) {
      if (value != null && value < 1) {
        throw ArgumentError.value(value, name, 'must be 1 or more');
      }
    }
    if (decimalPlaces < 0 || decimalPlaces > 3) {
      throw ArgumentError.value(
        decimalPlaces,
        'decimalPlaces',
        'must be 0 to 3',
      );
    }
    if (this.dropAfterRounds.length > 2) {
      throw ArgumentError.value(
        dropAfterRounds,
        'dropAfterRounds',
        'at most two',
      );
    }
    for (var i = 0; i < this.dropAfterRounds.length; i++) {
      final round = this.dropAfterRounds[i];
      if (round < 1 || (i > 0 && round <= this.dropAfterRounds[i - 1])) {
        throw ArgumentError.value(
          dropAfterRounds,
          'dropAfterRounds',
          'must be ascending integers of 1 or more',
        );
      }
    }
  }

  /// Reads the `core` part of a configuration, filling platform defaults.
  ///
  /// Throws [ArgumentError] for a value of the wrong type or an invalid
  /// combination.
  factory CoreOptions.fromMap(Map<String, Object?> map) {
    T read<T>(String key, T Function(Object value) parse, T fallback) {
      final value = map[key];
      if (value == null) return fallback;
      try {
        return parse(value);
      } on TypeError {
        throw ArgumentError.value(value, key, 'has the wrong type');
      }
    }

    T? readOptional<T>(String key, T Function(Object value) parse) {
      final value = map[key];
      if (value == null) return null;
      try {
        return parse(value);
      } on TypeError {
        throw ArgumentError.value(value, key, 'has the wrong type');
      }
    }

    bool asBool(Object v) => v as bool;
    int asInt(Object v) => v as int;
    E asEnum<E>(List<E> values, Object v, String Function(E) json) =>
        values.firstWhere(
          (e) => json(e) == v,
          orElse: () => throw ArgumentError.value(v, 'value', 'is not allowed'),
        );

    final drawMode = read(
      'draw_mode',
      (v) => asEnum(DrawMode.values, v, (e) => e.json),
      DrawMode.standardManOnMan,
    );
    final seeded = drawMode == DrawMode.seededManOnMan;
    return CoreOptions(
      teamsEnabled: read('teams_enabled', asBool, false),
      teamPilotCount: readOptional('team_pilot_count', asInt),
      teamProtection: read('team_protection', asBool, false),
      rolesEnabled: read('roles_enabled', asBool, false),
      drawMode: drawMode,
      preliminaryRounds:
          readOptional('preliminary_rounds', asInt) ?? (seeded ? 1 : null),
      laneMode: read(
        'lane_mode',
        (v) => asEnum(LaneMode.values, v, (e) => e.json),
        LaneMode.none,
      ),
      groupScoreMode: read(
        'group_score_mode',
        (v) => asEnum(GroupScoreMode.values, v, (e) => e.json),
        GroupScoreMode.normalized,
      ),
      roundingMode: read(
        'rounding_mode',
        (v) => asEnum(RoundingMode.values, v, (e) => e.json),
        RoundingMode.round,
      ),
      decimalPlaces: read('decimal_places', asInt, 1),
      dropAfterRounds: read(
        'drop_after_rounds',
        (v) => [for (final r in v as List) r as int],
        const <int>[],
      ),
      tiebreakerEnabled: read('tiebreaker_enabled', asBool, false),
      classesEnabled: read('classes_enabled', asBool, false),
      modelsEnabled: read('models_enabled', asBool, false),
      participantNumbersEnabled: read(
        'participant_numbers_enabled',
        asBool,
        false,
      ),
      reviewRequestsEnabled: read('review_requests_enabled', asBool, true),
      publicUpdateMode: read(
        'public_update_mode',
        (v) => asEnum(PublicUpdateMode.values, v, (e) => e.json),
        PublicUpdateMode.roundCompletion,
      ),
      intendedTotalRounds: readOptional('intended_total_rounds', asInt),
    );
  }

  /// Every key `core` may hold, as in `plan/data-model/contest-options.md`.
  static const knownKeys = {
    'teams_enabled',
    'team_pilot_count',
    'team_protection',
    'roles_enabled',
    'draw_mode',
    'preliminary_rounds',
    'lane_mode',
    'group_score_mode',
    'rounding_mode',
    'decimal_places',
    'drop_after_rounds',
    'tiebreaker_enabled',
    'classes_enabled',
    'models_enabled',
    'participant_numbers_enabled',
    'review_requests_enabled',
    'public_update_mode',
    'intended_total_rounds',
  };

  final bool teamsEnabled;

  /// Pilot scores counted for the team result; required with teams.
  final int? teamPilotCount;
  final bool teamProtection;
  final bool rolesEnabled;
  final DrawMode drawMode;

  /// Only for `SeededManOnMan`, where it defaults to 1.
  final int? preliminaryRounds;
  final LaneMode laneMode;
  final GroupScoreMode groupScoreMode;
  final RoundingMode roundingMode;
  final int decimalPlaces;

  /// Up to two ascending rounds after which each pilot's lowest score drops.
  final List<int> dropAfterRounds;
  final bool tiebreakerEnabled;
  final bool classesEnabled;
  final bool modelsEnabled;
  final bool participantNumbersEnabled;
  final bool reviewRequestsEnabled;
  final PublicUpdateMode publicUpdateMode;

  /// Only for `SeededManOnMan`; shown to people, with no effect on the draw.
  final int? intendedTotalRounds;

  @override
  List<Object?> get props => [
    teamsEnabled,
    teamPilotCount,
    teamProtection,
    rolesEnabled,
    drawMode,
    preliminaryRounds,
    laneMode,
    groupScoreMode,
    roundingMode,
    decimalPlaces,
    dropAfterRounds,
    tiebreakerEnabled,
    classesEnabled,
    modelsEnabled,
    participantNumbersEnabled,
    reviewRequestsEnabled,
    publicUpdateMode,
    intendedTotalRounds,
  ];
}
