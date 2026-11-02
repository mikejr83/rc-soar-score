import '../enums/audit_action.dart';
import '../enums/audit_outcome.dart';
import '../models/id.dart';
import '../models/scores/official_score.dart';
import '../models/scores/score_attempt.dart';
import '../models/sync/audit_event.dart';
import '../repositories/mutation_metadata.dart';

/// Where a corrected score sits, as read back from an event's `reason`.
class ScoreCorrectionRef {
  const ScoreCorrectionRef({required this.round, this.pilot});

  /// The pilot's participant number, or null when the text does not give one.
  final int? pilot;

  final int round;
}

/// The audit event of a director's correction of an official score.
///
/// A `ScoreAttempt` event has no field for the pilot, the round or the
/// points, so they travel in `reason` as
/// `correction: pilot 12; round 3; group 2; points 82.4 → 95.1; reason:
/// Timer misread`. The pilot is named by participant number, not by name: the
/// audit trail holds no names (see the retention proposal). A first entry is
/// not a correction and leaves no event.
abstract final class ScoreCorrectionAudit {
  /// The `ScoreAttempt` event for [attempt], which set [official] over the
  /// score at [previousRevision]. Stored in the same transaction as the
  /// correction.
  static AuditEvent event({
    required Id id,
    required ScoreAttempt attempt,
    required OfficialScore official,
    required int previousRevision,
    required int? pilotNumber,
    required int round,
    required int group,
    double? previousPoints,
    double? points,
    required MutationMetadata metadata,
    required DateTime at,
  }) => AuditEvent(
    id: id,
    entityType: attempt.entityType,
    entityId: attempt.id,
    contestId: attempt.contestId,
    action: AuditAction.scoreAttempt,
    actorId: metadata.actorId,
    authority: attempt.authority,
    installationId: metadata.sourceInstallationId,
    device: metadata.sourceDevice,
    baseRevision: previousRevision,
    resultingRevision: official.scoreRevision,
    serverTimestamp: at,
    clientTimestamp: metadata.clientTime,
    reason: reason(
      pilotNumber: pilotNumber,
      round: round,
      group: group,
      previousPoints: previousPoints,
      points: points,
      why: official.reason,
    ),
    outcome: AuditOutcome.success,
  );

  /// The `reason` text of a correction.
  static String reason({
    required int? pilotNumber,
    required int round,
    required int group,
    double? previousPoints,
    double? points,
    String? why,
  }) {
    final parts = [
      if (pilotNumber != null) 'pilot $pilotNumber',
      'round $round',
      'group $group',
      if (previousPoints != null && points != null)
        'points ${_points(previousPoints)} → ${_points(points)}',
      if (why != null && why.isNotEmpty) 'reason: $why',
    ];
    return 'correction: ${parts.join('; ')}';
  }

  /// The pilot and round named by [event], or null when it is not a score
  /// correction event written by [reason].
  static ScoreCorrectionRef? parse(AuditEvent event) =>
      parseReason(event.action, event.reason);

  /// As [parse], from the action and text of an event.
  static ScoreCorrectionRef? parseReason(AuditAction action, String? reason) {
    if (action != AuditAction.scoreAttempt ||
        reason == null ||
        !reason.startsWith('correction: ')) {
      return null;
    }
    final round = RegExp(r'round (\d+)').firstMatch(reason)?.group(1);
    if (round == null) return null;
    final pilot = RegExp(r'pilot (\d+)').firstMatch(reason)?.group(1);
    return ScoreCorrectionRef(
      round: int.parse(round),
      pilot: pilot == null ? null : int.parse(pilot),
    );
  }

  static String _points(double value) => value.toStringAsFixed(1);
}
