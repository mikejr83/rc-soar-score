import '../models/contest/contest.dart';
import '../models/contest/contest_configuration_revision.dart';
import '../models/contest/saved_configuration.dart';
import '../models/id.dart';
import '../models/sync/audit_event.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [ContestConfigurationRevision]s.
///
/// Revisions are append-only: a contest's configuration changes by adding the
/// next revision, never by editing one. Writes go through the unit of work
/// and name who made them.
abstract interface class ContestConfigurationRevisionRepository {
  Future<ContestConfigurationRevision?> findById(Id id);

  /// Every revision of [contestId], oldest first.
  Future<List<ContestConfigurationRevision>> listForContest(Id contestId);

  /// The revision of [contestId] with the highest number, or `null` when the
  /// contest has none.
  Future<ContestConfigurationRevision?> latestForContest(Id contestId);

  /// Stores a new [revision].
  ///
  /// Throws an `AlreadyStoredError` if one with the same id is stored.
  Future<ContestConfigurationRevision> append(
    ContestConfigurationRevision revision, {
    required MutationMetadata metadata,
  });

  /// Stores the next [revision] and, in the same transaction, the [contest]
  /// it changes (its update time and possibly its lifecycle state), so a
  /// configuration and the contest's state never disagree.
  ///
  /// The contest is saved like `ContestRepository.save`: its revision is
  /// bumped, and a `StaleRevisionError` is thrown when [contest] was read at
  /// an older revision, which also guards against two requests adding the
  /// same revision number. Throws an `AlreadyStoredError` if a revision with
  /// the same id is stored. Two mutations are recorded.
  ///
  /// An [audit] event is stored in the same transaction.
  Future<SavedConfiguration> appendWithContest(
    ContestConfigurationRevision revision, {
    required Contest contest,
    required MutationMetadata metadata,
    AuditEvent? audit,
  });
}
