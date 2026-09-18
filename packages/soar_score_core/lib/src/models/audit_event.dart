/// Represents an audit event.
///
/// Audit events cover all significant actions including state transitions,
/// score attempts, reviews, invitations, publication, and synchronization.
class AuditEvent {
  final String id;
  final String contestId;
  final String? entityId;
  final String action;
  final String? actor;
  final String? authority;
  final String? installation;
  final String? baseRevision;
  final String? resultingRevision;
  final DateTime serverTime;
  final DateTime? clientTime;
  final String? reason;
  final String? outcome;

  AuditEvent({
    required this.id,
    required this.contestId,
    this.entityId,
    required this.action,
    this.actor,
    this.authority,
    this.installation,
    this.baseRevision,
    this.resultingRevision,
    required this.serverTime,
    this.clientTime,
    this.reason,
    this.outcome,
  });
}