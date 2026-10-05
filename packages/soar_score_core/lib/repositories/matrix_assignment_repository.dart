import '../models/id.dart';
import '../models/matrix/matrix_assignment.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [MatrixAssignment]s.
///
/// Assignments are append-only. The one change to a stored row is the marker
/// that a move writes on the assignment it replaces.
abstract interface class MatrixAssignmentRepository {
  Future<MatrixAssignment?> findById(Id id);

  /// The assignments of [matrixRevisionId], in the order they were created.
  Future<List<MatrixAssignment>> listForRevision(Id matrixRevisionId);

  /// The assignments of [contestParticipationId], in the order they were
  /// created.
  Future<List<MatrixAssignment>> listForParticipation(
    Id contestParticipationId,
  );

  /// The assignments scheduled in [roundId] that no move has replaced.
  Future<List<MatrixAssignment>> listLiveForRound(Id roundId);

  /// Stores a new [assignment].
  ///
  /// Throws an `AlreadyStoredError` if one with the same id is stored.
  Future<MatrixAssignment> append(
    MatrixAssignment assignment, {
    required MutationMetadata metadata,
  });

  /// Stores [moved], an assignment of type `Moved`, and marks the assignment
  /// it moves from as replaced, in one transaction.
  ///
  /// Throws an `AlreadySupersededError` if the source was already moved.
  Future<MatrixAssignment> move(
    MatrixAssignment moved, {
    required MutationMetadata metadata,
  });
}
