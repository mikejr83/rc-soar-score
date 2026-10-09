import '../models/id.dart';
import '../models/teams/model_catalog.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for a director's private [ModelCatalog].
///
/// Entries are never shown to other directors; callers list by owner.
abstract interface class ModelCatalogRepository {
  Future<ModelCatalog?> findById(Id id);

  /// The entries owned by [ownerAccountId], by name.
  Future<List<ModelCatalog>> listForOwner(Id ownerAccountId);

  /// Stores [entry], bumping its revision, and records one mutation.
  ///
  /// Throws a `StaleRevisionError`, storing nothing, when [entry] was read at
  /// an older revision than the stored one.
  Future<ModelCatalog> save(
    ModelCatalog entry, {
    required MutationMetadata metadata,
  });

  /// Removes the entry [id] and records one mutation; returns `false` when it
  /// is not stored. Contest model links keep their own snapshot and are not
  /// touched.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
