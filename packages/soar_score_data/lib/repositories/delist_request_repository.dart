import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Delist requests in the database; backend only, so written without a
/// mutation.
class DelistRequestRepository extends DriftRepository
    implements core.DelistRequestRepository {
  DelistRequestRepository(super.db, {super.stores});

  late final _store = store<core.DelistRequest>('DelistRequest');

  @override
  Future<core.DelistRequest?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.DelistRequest>> listForPublication(core.Id publicationId) =>
      _store.whereId('publication_id', publicationId, orderBy: 'id');

  @override
  Future<core.DelistRequest?> findPendingForPublication(
    core.Id publicationId,
  ) async {
    final requests = await listForPublication(publicationId);
    return requests
        .where((r) => r.state == core.DelistState.pending)
        .firstOrNull;
  }

  @override
  Future<List<core.DelistRequest>> listByState(core.DelistState state) async {
    final requests = await _store.all(orderBy: 'id');
    return [
      for (final request in requests)
        if (request.state == state) request,
    ];
  }

  @override
  Future<core.DelistRequest> save(core.DelistRequest request) async {
    await _store.upsertJson(_store.encode(request));
    return request;
  }
}
