import '../models/id.dart';
import '../models/imports/import_provenance.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [ImportProvenance] rows, the stamps that
/// say where an imported entity came from.
abstract interface class ImportProvenanceRepository {
  Future<ImportProvenance?> findById(Id id);

  /// The stamps of [contestId] (the contest and its participations), by id.
  Future<List<ImportProvenance>> listForContest(Id contestId);

  /// The stamp of the entity [stampedEntityId], if it has one.
  Future<ImportProvenance?> findForEntity(Id stampedEntityId);

  /// The contest stamp of [ownerAccountId] with this [dedupeKey], if any: the
  /// earlier import of the same competition.
  Future<ImportProvenance?> findByDedupeKey(
    Id ownerAccountId,
    String dedupeKey,
  );

  /// Stores [stamp] and records one mutation. Throws a `StaleRevisionError`
  /// when it was read at an older revision, and a constraint error when a
  /// contest stamp repeats an owner's dedupe key.
  Future<ImportProvenance> save(
    ImportProvenance stamp, {
    required MutationMetadata metadata,
  });

  /// Removes the stamp [id] and records one mutation; returns `false` when
  /// it is not stored.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
