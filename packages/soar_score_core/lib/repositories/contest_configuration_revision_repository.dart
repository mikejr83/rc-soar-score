import '../models/contest/contest_configuration_revision.dart';
import '../models/id.dart';
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
}
