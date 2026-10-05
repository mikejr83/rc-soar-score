import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import '../sync/drift_unit_of_work.dart';
import '../sync/entity_store.dart';
import '../sync/entity_stores.dart';

/// What every Drift-backed repository needs: the stores and the unit of work.
///
/// Pass the same [stores] to several repositories to share them; otherwise
/// each builds its own from [db].
abstract class DriftRepository {
  DriftRepository(this.db, {EntityStores? stores})
    : stores = stores ?? EntityStores.forDatabase(db) {
    unitOfWork = DriftUnitOfWork(db, this.stores);
  }

  final SoarScoreDatabase db;
  final EntityStores stores;
  late final core.UnitOfWork unitOfWork;

  /// The store of [entityType], as the entity class [T].
  EntityStore<T> store<T extends Object>(String entityType) =>
      stores.of(entityType) as EntityStore<T>;
}
