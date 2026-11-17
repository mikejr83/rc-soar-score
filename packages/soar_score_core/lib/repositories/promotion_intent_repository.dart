import '../models/id.dart';
import '../models/scores/pending_promotion.dart';
import 'mutation_metadata.dart';

/// The `promote_score` intents of an installation's outbox.
///
/// An intent is an outbox mutation of the entity type `ScorePromotion`. It
/// changes no score, placeholder or review; those change only when the
/// service decides the intent and the receipt comes back.
abstract interface class PromotionIntentRepository {
  /// The intents of [contestId] the service has not decided, oldest first.
  Future<List<PendingPromotion>> pendingForContest(Id contestId);

  /// The undecided intent of the slot [assignmentId], or null.
  Future<PendingPromotion?> pendingForAssignment(Id contestId, Id assignmentId);

  /// Queues [intent] in the outbox. Nothing else is written.
  Future<void> queue(
    PendingPromotion intent, {
    required MutationMetadata metadata,
  });
}
