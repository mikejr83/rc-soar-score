import 'package:equatable/equatable.dart';

import '../../services/contest_scores.dart';
import 'matrix_assignment.dart';
import 'matrix_revision.dart';
import 'round.dart';
import 'round_group.dart';

/// The matrix of a contest as it stands: the latest finalized revision, the
/// rounds that are current, their groups, and the assignments that no move
/// has replaced.
///
/// Empty (no [revision]) until the first draw. Not an entity.
class CurrentMatrix extends Equatable {
  CurrentMatrix({
    this.revision,
    Iterable<Round> rounds = const [],
    Iterable<RoundGroup> groups = const [],
    Iterable<MatrixAssignment> assignments = const [],
    Iterable<RoundProgress> progress = const [],
  }) : rounds = List.unmodifiable(rounds),
       groups = List.unmodifiable(groups),
       assignments = List.unmodifiable(assignments),
       progress = List.unmodifiable(progress);

  factory CurrentMatrix.fromJson(Map<String, Object?> json) {
    final revision = json['revision'] as Map<String, Object?>?;
    List<T> list<T>(String key, T Function(Map<String, Object?>) read) => [
      for (final item in json[key] as List<Object?>)
        read(item as Map<String, Object?>),
    ];
    return CurrentMatrix(
      revision: revision == null ? null : MatrixRevision.fromJson(revision),
      rounds: list('rounds', Round.fromJson),
      groups: list('groups', RoundGroup.fromJson),
      assignments: list('assignments', MatrixAssignment.fromJson),
      progress: json['progress'] == null
          ? const []
          : list('progress', RoundProgress.fromJson),
    );
  }

  final MatrixRevision? revision;
  final List<Round> rounds;
  final List<RoundGroup> groups;
  final List<MatrixAssignment> assignments;

  /// How many flights of each current round have an official score, from the
  /// score placeholders of the live assignments. Empty before the first draw.
  final List<RoundProgress> progress;

  bool get isEmpty => revision == null;

  Map<String, Object?> toJson() => {
    'revision': revision?.toJson(),
    'rounds': [for (final round in rounds) round.toJson()],
    'groups': [for (final group in groups) group.toJson()],
    'assignments': [for (final item in assignments) item.toJson()],
    'progress': [for (final item in progress) item.toJson()],
  };

  @override
  List<Object?> get props => [revision, rounds, groups, assignments, progress];
}
