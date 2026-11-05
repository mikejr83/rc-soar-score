import '../models/imports/contest_import_plan.dart';
import '../models/imports/restore_plan.dart';
import 'mutation_metadata.dart';

/// Writes imported competitions as contests, with their provenance.
abstract interface class ContestImportRepository {
  /// Stamps the profiles an import created or updated, once per import
  /// operation, with one audit event each. Does nothing when there is no
  /// owner. Repeating a plan changes nothing. All or nothing.
  Future<void> stampProfiles(
    ProfileStampPlan plan, {
    required MutationMetadata metadata,
  });

  /// Writes [plan]'s competition as one contest in one transaction: contest,
  /// first configuration revision, roles it needs, teams, participations,
  /// model links, stamps and audit events. A failure part-way keeps nothing
  /// of this competition and does not affect other calls.
  ///
  /// Never throws for a competition-level problem; the result says what
  /// happened.
  Future<CompetitionImportResult> importCompetition(
    CompetitionImportPlan plan, {
    required MutationMetadata metadata,
  });

  /// What a restore of [identity] would meet: the contest an earlier import
  /// made of the same competition, whether its results are published, whether
  /// it reached the server, and what was changed in Soar Score since.
  Future<RestoreTarget> restoreTarget(
    ImportOwner owner,
    RestoreIdentity identity,
  );

  /// Restores [plan]'s competition in one transaction: creates the contest,
  /// or replaces the contents of the contest an earlier import made of the
  /// same competition, keeping its id. Contest, configuration, participations,
  /// draw, scores, re-flights, retirements and final state are written
  /// together, then every restored flight is recalculated and compared with
  /// GliderScore's score; a difference rolls everything back.
  ///
  /// Writes nothing when the content is unchanged. Never throws for a
  /// competition-level problem; the result says what happened.
  Future<RestoreImportResult> importRestore(
    RestoreImportPlan plan, {
    required MutationMetadata metadata,
  });
}
