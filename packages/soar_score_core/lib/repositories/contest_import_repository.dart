import '../models/imports/contest_import_plan.dart';
import '../models/imports/draw_import_draft.dart';
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

  /// What the draw import needs to know about the contest phase B made from
  /// competition [compNo] of the file with [fileFingerprint]: the contest, its
  /// stamp, whether it already has a matrix or an accepted score, and the
  /// pilots that have a participation. The contest stamp with the same
  /// fingerprint wins; otherwise the newest one. A competition with no
  /// stamped contest comes back with `stamped` false.
  Future<DrawImportTarget> drawTarget(
    ImportOwner owner,
    int compNo,
    String fileFingerprint,
  );

  /// Adds [plan]'s draw to its contest in one transaction: the finalized
  /// matrix revision(s) with rounds, groups, `Original` assignments and
  /// `NotEntered` score placeholders, the participant numbers, the contest
  /// moved from `Configuring` to `Ready`, a stamp per revision and the
  /// `Restoration` audit events. The fill rule is checked again inside the
  /// transaction. A failure part-way keeps nothing of this competition.
  ///
  /// Never throws for a competition-level problem; the result says what
  /// happened.
  Future<DrawImportResult> importDraw(
    DrawImportPlan plan, {
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
