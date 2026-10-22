import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'audit_event_dto.g.dart';

/// One audit event of a contest, as `GET /api/v1/contests/{id}/audit-events`
/// returns it.
///
/// A projection of [AuditEvent] without the sync and scope fields a reader
/// has no use for. For a director action, [transition] names the action and
/// [reason] holds the old and new value (`AdminLock Unlocked → Locked`).
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
@UtcTimestampConverter()
class AuditEventDto {
  const AuditEventDto({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.authority,
    required this.serverTimestamp,
    required this.outcome,
    this.transition,
    this.actorId,
    this.baseRevision,
    this.resultingRevision,
    this.reason,
  });

  factory AuditEventDto.fromEvent(AuditEvent event) => AuditEventDto(
    id: event.id,
    entityType: event.entityType,
    entityId: event.entityId,
    action: event.action,
    transition: event.action == AuditAction.stateTransition
        ? ContestTransitionAudit.actionOf(event)
        : null,
    actorId: event.actorId,
    authority: event.authority,
    baseRevision: event.baseRevision,
    resultingRevision: event.resultingRevision,
    serverTimestamp: event.serverTimestamp,
    reason: event.reason,
    outcome: event.outcome,
  );

  factory AuditEventDto.fromJson(Map<String, dynamic> json) =>
      _$AuditEventDtoFromJson(json);

  final Id id;
  final String entityType;
  final Id entityId;
  final AuditAction action;

  /// The director action of a `StateTransition` event; null for other events.
  final ContestAction? transition;

  /// The account that acted; null for an action by the system.
  final Id? actorId;
  final Authority authority;
  final int? baseRevision;
  final int? resultingRevision;

  /// When the service logged the event (UTC).
  final DateTime serverTimestamp;
  final String? reason;
  final AuditOutcome outcome;

  Map<String, dynamic> toJson() => _$AuditEventDtoToJson(this);
}
