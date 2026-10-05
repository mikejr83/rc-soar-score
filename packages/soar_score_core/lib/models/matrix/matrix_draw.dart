import 'package:equatable/equatable.dart';

import 'matrix_assignment.dart';
import 'matrix_revision.dart';
import 'round.dart';
import 'round_group.dart';

/// A matrix revision with everything a draw puts in it: its rounds, their
/// groups and the assignments of participants to them.
///
/// Stored as one unit, so a draw is complete or absent. Not an entity itself.
class MatrixDraw extends Equatable {
  MatrixDraw({
    required this.revision,
    required Iterable<Round> rounds,
    required Iterable<RoundGroup> groups,
    required Iterable<MatrixAssignment> assignments,
  }) : rounds = List.unmodifiable(rounds),
       groups = List.unmodifiable(groups),
       assignments = List.unmodifiable(assignments) {
    final roundIds = {for (final round in this.rounds) round.id};
    for (final round in this.rounds) {
      if (round.matrixRevisionId != revision.id) {
        throw ArgumentError('round ${round.id} belongs to another revision');
      }
    }
    for (final group in this.groups) {
      if (!roundIds.contains(group.roundId)) {
        throw ArgumentError('group ${group.id} belongs to another round');
      }
    }
    for (final assignment in this.assignments) {
      if (assignment.matrixRevisionId != revision.id) {
        throw ArgumentError(
          'assignment ${assignment.id} belongs to another revision',
        );
      }
    }
  }

  final MatrixRevision revision;
  final List<Round> rounds;
  final List<RoundGroup> groups;
  final List<MatrixAssignment> assignments;

  @override
  List<Object?> get props => [revision, rounds, groups, assignments];
}
