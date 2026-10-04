import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/audit_action.dart';
import '../../enums/audit_outcome.dart';
import '../../enums/authority.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'audit_event.g.dart';

/// An immutable, append-only record of a contested state change.
///
/// At most one of [contestId], [ownerAccountId] and [publicationId] identifies
/// the scope. See `plan/data-model/entities/audit_event.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class AuditEvent extends Equatable implements SyncScoped {
  AuditEvent({
    required this.id,
    required String entityType,
    required this.entityId,
    this.contestId,
    this.ownerAccountId,
    this.publicationId,
    required this.action,
    this.actorId,
    required this.authority,
    this.installationId,
    this.device,
    this.baseRevision,
    this.resultingRevision,
    required this.serverTimestamp,
    this.clientTimestamp,
    this.reason,
    this.outcome = AuditOutcome.success,
  }) : entityType = requireNotBlank(entityType, 'entityType') {
    final scopes = [contestId, ownerAccountId, publicationId];
    if (scopes.where((s) => s != null).length > 1) {
      throw ArgumentError(
        'at most one of contest_id, owner_account_id and publication_id may be set',
      );
    }
  }

  factory AuditEvent.fromJson(Map<String, Object?> json) =>
      _$AuditEventFromJson(json);

  final Id id;

  /// Type of the changed entity, for example `Contest` or `ScoreAttempt`.
  final String entityType;

  final Id entityId;
  final Id? contestId;

  /// The director whose own data the event concerns.
  final Id? ownerAccountId;

  /// Not a foreign key, so the event outlives the publication's content.
  final Id? publicationId;

  final AuditAction action;

  /// The account that acted; null for an action by the system.
  final Id? actorId;

  final Authority authority;
  final Id? installationId;
  final String? device;

  /// Pre-mutation revision, when applicable.
  final int? baseRevision;

  /// Post-mutation revision, when applicable.
  final int? resultingRevision;

  /// Time the service logged the event; authoritative for ordering.
  final DateTime serverTimestamp;

  /// Time the client generated the event; for audit only.
  final DateTime? clientTimestamp;

  final String? reason;
  final AuditOutcome outcome;

  /// Contest events travel the contest stream and director events the
  /// director stream. An event outside both, such as a publication event, is
  /// not synchronized.
  @override
  SyncScope get syncScope {
    if (contestId != null) return SyncScope.contest;
    if (ownerAccountId != null) return SyncScope.director;
    return SyncScope.backendOnly;
  }

  Map<String, Object?> toJson() => _$AuditEventToJson(this);

  @override
  List<Object?> get props => [
    id,
    entityType,
    entityId,
    contestId,
    ownerAccountId,
    publicationId,
    action,
    actorId,
    authority,
    installationId,
    device,
    baseRevision,
    resultingRevision,
    serverTimestamp,
    clientTimestamp,
    reason,
    outcome,
  ];
}
