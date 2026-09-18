import 'package:json_annotation/json_annotation.dart';

part 'contest_config.g.dart';

/// Supported RC soaring contest disciplines.
enum Discipline {
  ales,
  thermalDuration,
  f3j,
  f5j,
  f3k,
}

/// How to compute the group score from raw scores.
enum GroupScoreType {
  /// Normalize flight time to 1000, then add landing bonus.
  time,
  /// Add flight score + landing bonus, then normalize to 1000.
  normalized,
}

/// How to round the final contest total score.
enum TotalScoreRounding {
  truncate0,
  truncate1,
  truncate2,
  truncate3,
  round0,
  round1,
  round2,
  round3,
}

/// How motor restarts are handled in F5J.
enum MotorRestartMode {
  /// Restart allowed, pilot gets 0, round can be dropped.
  allowed,
  /// Restart allowed, pilot gets 0, round cannot be dropped.
  nonDroppableZero,
  /// Motor restarts not allowed in this contest.
  notAllowed,
}

/// F3K task type identifier.
enum F3kTaskType {
  taskA, // Last flight
  taskB, // Next to last and last flight
  taskC, // All up, Last Down
  taskD, // Two flights
  taskE, // Poker - variable target time
  taskF, // Three of six
  taskG, // Five longest flights
  taskH, // Ladder - three targets
  taskI, // Three longest flights
  taskJ, // Three last flights
  taskK, // Big ladder - increasing time
  taskL, // One flight
  taskM, // Fly-off increasing time
  taskN, // Best flight - extended
}

/// Contest scoring configuration.
///
/// This is the immutable configuration that the scoring engine uses
/// to compute all scores. It includes discipline, target/working time,
/// points per second, fractional seconds, and rounding mode.
@JsonSerializable()
class ContestScoringConfig {
  final Discipline discipline;
  final double targetTimeSeconds;
  final int fractionalSeconds;
  final double pointsPerSecond;
  final GroupScoreType groupScoreType;
  final TotalScoreRounding totalScoreRounding;
  final int? droppedRounds;
  final bool useTeams;
  final int? f3jWorkingTimeSeconds;
  final int? f5jWorkingTimeSeconds;
  final MotorRestartMode? f5jMotorRestart;
  final double? f5jHeightPenaltyPerMeter;
  final double? f5jReferenceAltitudeMeters;
  final double? f5jAboveReferencePenaltyPerMeter;
  final F3kTaskType? f3kTaskType;

  ContestScoringConfig({
    required this.discipline,
    required this.targetTimeSeconds,
    this.fractionalSeconds = 0,
    this.pointsPerSecond = 1.0,
    this.groupScoreType = GroupScoreType.normalized,
    this.totalScoreRounding = TotalScoreRounding.round1,
    this.droppedRounds,
    this.useTeams = false,
    this.f3jWorkingTimeSeconds,
    this.f5jWorkingTimeSeconds,
    this.f5jMotorRestart,
    this.f5jHeightPenaltyPerMeter,
    this.f5jReferenceAltitudeMeters,
    this.f5jAboveReferencePenaltyPerMeter,
    this.f3kTaskType,
  });

  factory ContestScoringConfig.fromJson(Map<String, dynamic> json) =>
      _$ContestScoringConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ContestScoringConfigToJson(this);
}

/// Discipline-specific flight components entered by participant or official.
class FlightComponents {
  /// Flight duration in seconds.
  final double durationSeconds;
  /// Landing bonus points (from configured landing table).
  final int landingBonus;
  /// Pilot indicated out-of-bounds landing.
  final bool outOfBounds;
  /// Pilot indicated over-flight of more than 1 minute past target/working time.
  final bool overflightOverOneMinute;
  /// Pilot indicated motor restart (applicable to ALES, F5J).
  final bool motorRestart;
  /// Pilot indicated late landing - did not land before working time expired.
  final bool lateLanding;
  /// F5J: Launch altitude in meters.
  final double? launchAltitudeMeters;
  /// F5J: Distance penalty in seconds.
  final double? distancePenaltySeconds;

  FlightComponents({
    required this.durationSeconds,
    this.landingBonus = 0,
    this.outOfBounds = false,
    this.overflightOverOneMinute = false,
    this.motorRestart = false,
    this.lateLanding = false,
    this.launchAltitudeMeters,
    this.distancePenaltySeconds,
  });
}