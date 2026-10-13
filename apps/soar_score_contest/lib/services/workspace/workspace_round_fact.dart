import 'package:equatable/equatable.dart';

import '../matrix/round_progress_view.dart';

/// One round's scoring progress.
class WorkspaceRoundFact extends Equatable {
  const WorkspaceRoundFact({
    required this.ordinal,
    required this.groupCount,
    required this.scored,
    required this.total,
    required this.state,
  });

  final int ordinal;

  /// How many groups the round has.
  final int groupCount;
  final int scored;
  final int total;
  final RoundProgressState state;

  @override
  List<Object?> get props => [ordinal, groupCount, scored, total, state];
}
