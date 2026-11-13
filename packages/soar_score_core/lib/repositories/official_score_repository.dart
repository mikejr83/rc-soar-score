import '../models/id.dart';
import '../models/scores/official_score.dart';
import '../models/scores/score_placeholder.dart';
import 'mutation_metadata.dart';
import 'recorded_score.dart';

/// Abstract persistence contract for [OfficialScore]s.
///
/// Official scores are append-only: a correction is the next score revision.
abstract interface class OfficialScoreRepository {
  Future<OfficialScore?> findById(Id id);

  /// Runs [body] as the only score writer of [contestId], in one transaction.
  ///
  /// Every writer of a contest's score state (director entry, participant
  /// submission, promotion) reads, checks and writes inside this gate, so a
  /// competing writer waits for the commit and then reads its result. On
  /// PostgreSQL the gate is the contest's advisory lock, taken before any
  /// read; SQLite's writer transaction begins immediately. Nested use joins
  /// the outer gate. Everything [body] writes commits or rolls back together.
  Future<T> withContestGate<T>(Id contestId, Future<T> Function() body);

  /// The official scores of [scorePlaceholderId], by score revision.
  Future<List<OfficialScore>> listForPlaceholder(Id scorePlaceholderId);

  /// The official score of [scorePlaceholderId] with the highest score
  /// revision, or `null` when none is set.
  Future<OfficialScore?> currentForPlaceholder(Id scorePlaceholderId);

  /// The current official score of each of [scorePlaceholderIds] that has
  /// one, by placeholder id, in one read.
  Future<Map<Id, OfficialScore>> currentForPlaceholders(
    Iterable<Id> scorePlaceholderIds,
  );

  /// When the latest official score of each of [contestIds] was set, in one
  /// read. A contest with no score is absent from the map.
  Future<Map<Id, DateTime>> latestSetAtForContests(Iterable<Id> contestIds);

  /// Stores a new [score].
  ///
  /// Throws an `AlreadyStoredError` if one with the same id is stored.
  Future<OfficialScore> append(
    OfficialScore score, {
    required MutationMetadata metadata,
  });

  /// Stores [score] and the updated [placeholder] it belongs to, in one
  /// transaction.
  ///
  /// Throws an `ArgumentError` if [placeholder] is not the score's, or does
  /// not carry the score's revision, and a `StaleRevisionError` if it was
  /// read at an older revision.
  Future<OfficialScore> recordOfficial(
    OfficialScore score,
    ScorePlaceholder placeholder, {
    required MutationMetadata metadata,
  });

  /// Stores the adoption of a participant submission as the official score:
  /// the official version, the placeholder in its new state, the superseded
  /// reviews and their audit events, in one transaction.
  ///
  /// Throws an `ArgumentError` if the parts do not belong together, and a
  /// `StaleRevisionError` when the placeholder or a review changed since it
  /// was read. Nothing is stored then.
  Future<PromotedScore> recordPromotion(
    PromotedScore promotion, {
    required MutationMetadata metadata,
  });

  /// Stores a director's score entry: the [RecordedScore.attempt], the
  /// official score taken from it, the placeholder in its new state and, when
  /// given, the contest, in one transaction.
  ///
  /// Throws a `StaleRevisionError` when the placeholder or the contest changed
  /// since it was read, and an `AlreadyStoredError` when the attempt or the
  /// official score is already stored. Nothing is stored then.
  Future<RecordedScore> recordEntry(
    RecordedScore entry, {
    required MutationMetadata metadata,
  });

  /// Stores several director score entries in ONE transaction: everything of
  /// every entry, or nothing.
  ///
  /// The entries are for different slots, and at most one of them carries the
  /// contest. Throws a `StaleRevisionError` or an `AlreadyStoredError` when
  /// any entry's placeholder, contest or ids conflict; nothing is stored
  /// then, and the caller can fall back to [recordEntry] one by one.
  Future<List<RecordedScore>> recordEntries(
    List<RecordedScore> entries, {
    required MutationMetadata metadata,
  });
}
