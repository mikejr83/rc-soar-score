import '../models/contest/contest.dart';
import '../models/id.dart';
import '../models/scores/official_score.dart';
import '../models/scores/score_attempt.dart';
import '../models/scores/review_request.dart';
import '../models/scores/score_placeholder.dart';
import '../models/sync/audit_event.dart';

/// A score entry ready to store: the attempt, the official score taken from
/// it and the placeholder in its new state, with the contest when the entry
/// moved it on (the first accepted score changes `Ready` to `Running`).
///
/// `OfficialScoreRepository.recordEntry` stores all of it, or none.
class RecordedScore {
  const RecordedScore({
    required this.attempt,
    required this.officialScore,
    required this.placeholder,
    this.contest,
    this.audit,
  });

  final ScoreAttempt attempt;
  final OfficialScore officialScore;

  /// The placeholder as it must be stored, at the revision it was read at.
  final ScorePlaceholder placeholder;

  /// The contest to store with the entry, or null when it does not change.
  final Contest? contest;

  /// The audit event of a correction, stored in the same transaction, or null
  /// for a first entry (which is not audited).
  final AuditEvent? audit;
}

/// A stored participant submission adopted as the official score: the new
/// official version (citing the submission as its source), the placeholder in
/// its new state and the open reviews the adoption superseded, with their
/// audit events.
///
/// `OfficialScoreRepository.recordPromotion` stores all of it, or none.
class PromotedScore {
  const PromotedScore({
    required this.officialScore,
    required this.placeholder,
    this.supersededReviews = const [],
    this.audits = const [],
    this.receipt,
    this.confirmsExisting = false,
  });

  /// The official version the adoption made; with [confirmsExisting] the
  /// version that is already stored and was confirmed.
  final OfficialScore officialScore;

  /// True when [officialScore] is already stored and only the placeholder's
  /// review closure (and the superseded reviews) are written: a director's
  /// confirmation of an automatically accepted score, which creates no second
  /// official version.
  final bool confirmsExisting;

  /// The placeholder as it must be stored, at the revision it was read at.
  final ScorePlaceholder placeholder;

  /// Reviews that were open on the slot, already in state `Superseded`.
  final List<ReviewRequest> supersededReviews;

  /// Audit events stored with the promotion.
  final List<AuditEvent> audits;

  /// The receipt of the sync operation that asked for the adoption, stored in
  /// the same transaction and last of the aggregate; null for an adoption made
  /// by a route of the service.
  final PromotionReceipt? receipt;
}

/// The entity type of a promotion receipt and of the `promote_score` intent
/// that asked for it. It names an operation, not a stored entity.
const promotionReceiptEntityType = 'ScorePromotion';

/// The service's durable record that it decided a `promote_score` intent of an
/// installation in favour of the adoption.
class PromotionReceipt {
  const PromotionReceipt({
    required this.operationId,
    required this.clientMutationId,
    required this.payload,
  });

  /// The intent's operation id (the receipt's `entity_id`).
  final Id operationId;

  /// The intent's `client_mutation_id`, so a retry finds the receipt.
  final String clientMutationId;

  /// The intent's payload, as sent.
  final Map<String, Object?> payload;
}
