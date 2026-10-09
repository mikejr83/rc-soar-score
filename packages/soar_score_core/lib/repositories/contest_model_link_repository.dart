import '../models/id.dart';
import '../models/teams/contest_model_link.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [ContestModelLink]s, the contest's
/// snapshot of the model a participant flies.
abstract interface class ContestModelLinkRepository {
  Future<ContestModelLink?> findById(Id id);

  /// The link of [contestParticipationId], or `null`. A participation has at
  /// most one.
  Future<ContestModelLink?> findForParticipation(Id contestParticipationId);

  /// Every link of [contestId], by id.
  Future<List<ContestModelLink>> listForContest(Id contestId);

  /// Stores [link], bumping its revision, and records one mutation.
  ///
  /// Throws a `StaleRevisionError`, storing nothing, when [link] was read at
  /// an older revision than the stored one.
  Future<ContestModelLink> save(
    ContestModelLink link, {
    required MutationMetadata metadata,
  });

  /// Removes the link [id] and records one mutation; returns `false` when it
  /// is not stored.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
