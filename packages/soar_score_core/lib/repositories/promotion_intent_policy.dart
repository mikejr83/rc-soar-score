import '../models/id.dart';

/// Decides whether marking a score official on this installation is queued as
/// a `promote_score` intent for the service to decide, or written directly.
///
/// An installation queues the intent once its contest syncs and the first
/// upload has finished; before that, and on the service itself, the adoption
/// is written as it always was.
abstract interface class PromotionIntentPolicy {
  /// Whether an adoption in [contestId] is queued instead of written.
  Future<bool> queuesPromotions(Id contestId);
}

/// The policy where adoptions are always written directly: the service, and
/// an installation whose contest does not sync.
class NoPromotionIntents implements PromotionIntentPolicy {
  const NoPromotionIntents();

  @override
  Future<bool> queuesPromotions(Id contestId) async => false;
}
