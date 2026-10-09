import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Model catalog entries in the database.
class ModelCatalogRepository extends DriftRepository
    implements core.ModelCatalogRepository {
  ModelCatalogRepository(super.db, {super.stores});

  late final _store = store<core.ModelCatalog>('ModelCatalog');

  @override
  Future<core.ModelCatalog?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.ModelCatalog>> listForOwner(core.Id ownerAccountId) =>
      _store.whereId('owner_account_id', ownerAccountId, orderBy: 'name, id');

  @override
  Future<core.ModelCatalog> save(
    core.ModelCatalog entry, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) => context.save(entry, metadata: metadata));

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final entry = await _store.find(id);
        if (entry == null) return false;
        await context.delete(entry, metadata: metadata);
        return true;
      });
}
