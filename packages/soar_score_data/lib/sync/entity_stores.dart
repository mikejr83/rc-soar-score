import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import 'entity_store.dart';
import 'table_mapper.dart';

/// The entity types a database can store, by `entity_type`.
class EntityStores {
  EntityStores(Iterable<EntityStore<core.SyncScoped>> stores)
    : _byType = {for (final store in stores) store.entityType: store};

  /// Every store of [db]'s profile.
  factory EntityStores.forDatabase(SoarScoreDatabase db) => EntityStores([
    EntityStore<core.Contest>(
      entityType: 'Contest',
      mapper: TableMapper(db, db.contests),
      decode: core.Contest.fromJson,
      encode: (contest) => contest.toJson(),
    ),
  ]);

  final Map<String, EntityStore<core.SyncScoped>> _byType;

  /// The store for [entityType]; throws an [ArgumentError] for an unknown one.
  EntityStore<core.SyncScoped> of(String entityType) =>
      _byType[entityType] ??
      (throw ArgumentError.value(
        entityType,
        'entityType',
        'has no store in this database',
      ));
}
