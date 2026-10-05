import '../models/id.dart';
import '../models/matrix/matrix_draw.dart';
import '../models/matrix/matrix_revision.dart';
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
}
