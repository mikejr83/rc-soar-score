import '../models/contest/contest.dart';
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
  });

  final OfficialScore officialScore;

  /// The placeholder as it must be stored, at the revision it was read at.
  final ScorePlaceholder placeholder;

  /// Reviews that were open on the slot, already in state `Superseded`.
  final List<ReviewRequest> supersededReviews;

  /// Audit events stored with the promotion.
  final List<AuditEvent> audits;
}
