import 'package:json_annotation/json_annotation.dart';

/// The kind of action an audit event records.
///
/// Serializes as the exact text in `plan/data-model/enumerations.md`.
enum AuditAction {
  @JsonValue('StateTransition')
  stateTransition,
  @JsonValue('ScoreAttempt')
  scoreAttempt,
  @JsonValue('ScoreReview')
  scoreReview,
  @JsonValue('InvitationIssued')
  invitationIssued,
  @JsonValue('InvitationReplaced')
  invitationReplaced,
  @JsonValue('InvitationRevoked')
  invitationRevoked,
  @JsonValue('InvitationDeliveryRequested')
  invitationDeliveryRequested,
  @JsonValue('InvitationAccessed')
  invitationAccessed,
  @JsonValue('InvitationAccessFailed')
  invitationAccessFailed,
  @JsonValue('PublicationAttempt')
  publicationAttempt,
  @JsonValue('DelistRequested')
  delistRequested,
  @JsonValue('DelistDecided')
  delistDecided,
  @JsonValue('DelistWithdrawn')
  delistWithdrawn,
  @JsonValue('Redaction')
  redaction,
  @JsonValue('Conflict')
  conflict,
  @JsonValue('ConflictAccepted')
  conflictAccepted,
  @JsonValue('ConflictRejected')
  conflictRejected,
  @JsonValue('Deletion')
  deletion,
  @JsonValue('Restoration')
  restoration,
  @JsonValue('InstallationActivation')
  installationActivation,
}
