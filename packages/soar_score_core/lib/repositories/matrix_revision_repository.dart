import '../models/id.dart';
import '../models/matrix/matrix_draw.dart';
import '../models/matrix/matrix_revision.dart';
import '../models/sync/audit_event.dart';
import 'finalized_draw.dart';
import 'finalized_redraw.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [MatrixRevision]s and the draws in them.
///
/// Revisions are append-only: a redraw adds the next revision.
abstract interface class MatrixRevisionRepository {
  Future<MatrixRevision?> findById(Id id);

  /// Every revision of [contestId], oldest first.
  Future<List<MatrixRevision>> listForContest(Id contestId);

  /// The revision of [contestId] with the highest number, or `null` when the
  /// contest has none.
  Future<MatrixRevision?> latestForContest(Id contestId);

  /// Stores [draw]: its revision, rounds, groups and assignments, in one
  /// transaction, so a draw is complete or absent.
  ///
  /// Each stored entity gets its own mutation, derived from [metadata] with
  /// `MutationMetadata.forPart`. Throws an `AlreadyStoredError` if the
  /// revision or one of the assignments is already stored.
  Future<MatrixDraw> appendDraw(
    MatrixDraw draw, {
    required MutationMetadata metadata,
  });

  /// Stores [finalized]: the draw (as [appendDraw] does), its score
  /// placeholders, the participant numbers and the contest, in one
  /// transaction.
  ///
  /// Throws an `AlreadyStoredError` if the revision, an assignment or a
  /// placeholder is already stored, and a `StaleRevisionError` if the
  /// contest or a participation changed since it was read. Each stored entity
  /// gets its own mutation, derived from [metadata] with
  /// `MutationMetadata.forPart`.
  ///
  /// An [audit] event is stored in the same transaction as the draw, so
  /// either both are kept or neither is.
  Future<FinalizedDraw> appendFinalizedDraw(
    FinalizedDraw finalized, {
    required MutationMetadata metadata,
    AuditEvent? audit,
  });

  /// Stores [finalized], a later revision: the replaced rounds first (so
  /// their ordinals are free), then the draw, its score placeholders and the
  /// participant numbers, in one transaction. [expectedBaseRevision] is the
  /// newest revision number when the caller read the matrix: the store
  /// re-checks it inside the transaction and throws a `ContestStateError`
  /// with the `stale_matrix` code when it is no longer the newest. A redraw
  /// that passes that check can still lose it to a concurrent redraw that
  /// claims the successor first; the loser stores nothing and is answered
  /// with the same `stale_matrix`.
  ///
  /// Throws an `AlreadyStoredError` if the revision, an assignment or a
  /// placeholder is already stored, and a `StaleRevisionError` if a replaced
  /// round or a participation changed since it was read, unless the failure
  /// was of the just-rejected kind. Each stored entity gets its own mutation,
  /// derived from [metadata] with `MutationMetadata.forPart`.
  ///
  /// An [audit] event is stored in the same transaction as the redraw, so
  /// either both are kept or neither is.
  Future<FinalizedRedraw> appendRedraw(
    FinalizedRedraw finalized, {
    required int expectedBaseRevision,
    required MutationMetadata metadata,
    AuditEvent? audit,
  });
}
