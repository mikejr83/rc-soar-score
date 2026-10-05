import '../models/id.dart';
import '../models/teams/team.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [Team]s.
abstract interface class TeamRepository {
  Future<Team?> findById(Id id);

  /// The teams of [contestId], by name.
  Future<List<Team>> listForContest(Id contestId);

  /// Inserts [team], or updates the stored row with the same id.
  ///
  /// Throws a `StaleRevisionError` when [team] was read at an older revision.
  /// Returns the team as stored.
  Future<Team> save(Team team, {required MutationMetadata metadata});

  /// Deletes the team with [id] and its memberships, in one transaction;
  /// returns whether a row was removed.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
