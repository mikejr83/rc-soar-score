import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// An outbox row as it is sent to the service.
SyncMutationDto mutationToDto(MutationRecord mutation) => SyncMutationDto(
  id: mutation.id,
  clientMutationId: mutation.clientMutationId,
  entityType: mutation.entityType,
  entityId: mutation.entityId,
  baseRevision: mutation.baseRevision,
  authority: mutation.authority,
  clientTime: mutation.clientTime,
  dependsOnMutationId: mutation.dependsOnMutationId,
  payload: mutation.payload,
);

/// A change from the service as the applier takes it. A deletion arrives as
/// the payload `{"deleted": true}`.
ReplicatedChange changeFromDto(SyncScopeKey scope, SyncChangeDto change) =>
    ReplicatedChange(
      scope: scope,
      sequence: change.sequence,
      entityType: change.entityType,
      entityId: change.entityId,
      revision: change.revision,
      payload: change.payload,
      isDelete: change.payload['deleted'] == true,
    );

/// The wire scope of [scope]. System data has no exchange scope.
SyncScopeDto scopeToDto(SyncScopeKey scope) => switch (scope) {
  ContestScopeKey(:final contestId) => SyncScopeDto.contest(contestId),
  DirectorScopeKey(:final ownerAccountId) => SyncScopeDto.owner(ownerAccountId),
  SystemScopeKey() => throw ArgumentError.value(
    scope,
    'scope',
    'system data has its own stream, not an exchange',
  ),
};
