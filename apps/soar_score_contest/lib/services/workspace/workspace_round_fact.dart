import 'package:equatable/equatable.dart';

import '../matrix/round_progress_view.dart';

/// One round's scoring progress.
class WorkspaceRoundFact extends Equatable {
  const WorkspaceRoundFact({
    required this.ordinal,
    required this.scored,
    required this.total,
    required this.state,
  });

  final int ordinal;
  final int scored;
  final int total;
  final RoundProgressState state;

  @override
  List<Object?> get props => [ordinal, scored, total, state];
}
