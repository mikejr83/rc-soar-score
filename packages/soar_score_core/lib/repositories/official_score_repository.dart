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

  /// The official scores of [scorePlaceholderId], by score revision.
  Future<List<OfficialScore>> listForPlaceholder(Id scorePlaceholderId);

  /// The official score of [scorePlaceholderId] with the highest score
  /// revision, or `null` when none is set.
  Future<OfficialScore?> currentForPlaceholder(Id scorePlaceholderId);

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
}
