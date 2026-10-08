import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Publication projections in the database; append-only and backend only, so
/// written without a mutation.
class PublicationProjectionRepository extends DriftRepository
    implements core.PublicationProjectionRepository {
  PublicationProjectionRepository(super.db, {super.stores});

  late final _store = store<core.PublicationProjection>(
    'PublicationProjection',
  );

  @override
  Future<core.PublicationProjection?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.PublicationProjection>> listForPublication(
    core.Id publicationId,
  ) => _store.whereId(
    'publication_id',
    publicationId,
    orderBy: 'projection_revision',
  );

  @override
  Future<core.PublicationProjection?> latestForPublication(
    core.Id publicationId,
  ) async {
    final projections = await listForPublication(publicationId);
    return projections.isEmpty ? null : projections.last;
  }

  @override
  Future<core.PublicationProjection?> findByClientMutationId(
    core.Id publicationId,
    String clientMutationId,
  ) async {
    final projections = await listForPublication(publicationId);
    return projections
        .where((p) => p.clientMutationId == clientMutationId)
        .firstOrNull;
  }

  @override
  Future<core.PublicationProjection> append(
    core.PublicationProjection projection,
  ) => db.transaction(() async {
    if (await _store.findJson(projection.id) != null) {
      throw core.AlreadyStoredError(
        entityType: _store.entityType,
        entityId: projection.id,
      );
    }
    await _store.upsertJson(_store.encode(projection));
    return projection;
  });
}
