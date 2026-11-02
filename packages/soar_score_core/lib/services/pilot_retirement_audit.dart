import '../enums/audit_action.dart';
import '../enums/audit_outcome.dart';
import '../models/id.dart';
import '../models/participants/contest_participation.dart';
import '../models/sync/audit_event.dart';
import '../repositories/mutation_metadata.dart';

/// What a retirement event says happened.
enum PilotRetirementKind { retire, reinstate }

/// The pilot and round named by a retirement event.
class PilotRetirementRef {
  const PilotRetirementRef({
    required this.kind,
    required this.round,
    this.pilot,
  });

  final PilotRetirementKind kind;

  /// The pilot's participant number, or null when the text does not give one.
  final int? pilot;

  /// The round the pilot retires from; for a reinstatement, the round they
  /// had retired from.
  final int round;
}

/// The audit event of a pilot retiring or being reinstated.
///
/// It is a `StateTransition` event on the `ContestParticipation`; the effect
/// travels in `reason` as `retire: pilot 12; from round 3`,
/// `retire: pilot 12; from round 2 → 4` (the round moved) or
/// `reinstate: pilot 12; was retired from round 3`. Contest director actions
/// use the same action with a `ContestAction` name in front, which this text
/// never matches.
abstract final class PilotRetirementAudit {
  /// The event for [after] replacing [before], or null when the retirement
  /// round did not change. Stored in the same transaction as the change.
  static AuditEvent? event({
    required Id id,
    required ContestParticipation before,
    required ContestParticipation after,
    required MutationMetadata metadata,
    required DateTime at,
  }) {
    final was = before.retiredAtRound;
    final now = after.retiredAtRound;
    if (was == now) return null;
    final pilot = after.participantNumber == null
        ? ''
        : 'pilot ${after.participantNumber}; ';
    final reason = now == null
        ? 'reinstate: ${pilot}was retired from round $was'
        : was == null
        ? 'retire: ${pilot}from round $now'
        : 'retire: ${pilot}from round $was → $now';
    return AuditEvent(
      id: id,
      entityType: after.entityType,
      entityId: after.id,
      contestId: after.contestId,
      action: AuditAction.stateTransition,
      actorId: metadata.actorId,
      authority: metadata.authority,
      installationId: metadata.sourceInstallationId,
      device: metadata.sourceDevice,
      baseRevision: before.revision,
      resultingRevision: before.revision + 1,
      serverTimestamp: at,
      clientTimestamp: metadata.clientTime,
      reason: reason,
      outcome: AuditOutcome.success,
    );
  }

  /// What [event] records, or null when it is not a retirement event written
  /// by [event].
  static PilotRetirementRef? parse(AuditEvent event) =>
      parseReason(event.action, event.reason);

  /// As [parse], from the action and text of an event.
  static PilotRetirementRef? parseReason(AuditAction action, String? reason) {
    if (action != AuditAction.stateTransition || reason == null) return null;
    final kind = reason.startsWith('retire: ')
        ? PilotRetirementKind.retire
        : reason.startsWith('reinstate: ')
        ? PilotRetirementKind.reinstate
        : null;
    if (kind == null) return null;
    // A move reads `from round 2 → 4`: the round now is the last number.
    final rounds = RegExp(r'round (\d+)(?: → (\d+))?').firstMatch(reason);
    if (rounds == null) return null;
    final round = rounds.group(2) ?? rounds.group(1)!;
    final pilot = RegExp(r'pilot (\d+)').firstMatch(reason)?.group(1);
    return PilotRetirementRef(
      kind: kind,
      round: int.parse(round),
      pilot: pilot == null ? null : int.parse(pilot),
    );
  }
}
