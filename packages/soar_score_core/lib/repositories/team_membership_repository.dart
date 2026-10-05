import '../models/id.dart';
import '../models/teams/team_membership.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [TeamMembership]s.
abstract interface class TeamMembershipRepository {
  Future<TeamMembership?> findById(Id id);

  /// The memberships of [teamId], in the order they were created.
  Future<List<TeamMembership>> listForTeam(Id teamId);

  /// Every membership in [contestId].
  Future<List<TeamMembership>> listForContest(Id contestId);

  /// Inserts [membership], or updates the stored row with the same id.
  ///
  /// Throws a `StaleRevisionError` when it was read at an older revision.
  /// Returns the membership as stored.
  Future<TeamMembership> save(
    TeamMembership membership, {
    required MutationMetadata metadata,
  });

  /// Deletes the membership with [id]; returns whether a row was removed.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
