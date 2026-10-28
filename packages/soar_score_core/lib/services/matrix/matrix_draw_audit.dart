import '../../enums/audit_action.dart';
import '../../enums/audit_outcome.dart';
import '../../models/id.dart';
import '../../models/matrix/matrix_revision.dart';
import '../../models/sync/audit_event.dart';
import '../../repositories/mutation_metadata.dart';

/// The audit event of a matrix draw, first draw or redraw alike.
abstract final class MatrixDrawAudit {
  /// The `MatrixDrawn` event for [revision], stored in the same transaction as
  /// the draw. `base_revision` is the previous revision number (none for the
  /// first draw) and `resulting_revision` the new one; `reason` is the
  /// revision's own reason.
  static AuditEvent event({
    required Id id,
    required MatrixRevision revision,
    required MutationMetadata metadata,
    required DateTime at,
  }) => AuditEvent(
    id: id,
    entityType: revision.entityType,
    entityId: revision.id,
    contestId: revision.contestId,
    action: AuditAction.matrixDrawn,
    actorId: metadata.actorId,
    authority: metadata.authority,
    installationId: metadata.sourceInstallationId,
    device: metadata.sourceDevice,
    baseRevision: revision.revisionNumber > 1
        ? revision.revisionNumber - 1
        : null,
    resultingRevision: revision.revisionNumber,
    serverTimestamp: at,
    clientTimestamp: metadata.clientTime,
    reason: revision.reason,
    outcome: AuditOutcome.success,
  );
}
