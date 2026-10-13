import 'package:equatable/equatable.dart';

import 'sync_problem.dart';

/// What came of sending the director's decision for a conflict.
class ConflictAnswer extends Equatable {
  /// The service accepted the decision. [refreshProblem] is set when the sync
  /// that follows could not store the answer, so the conflict can still show
  /// until the next successful sync.
  const ConflictAnswer.resolved({this.refreshProblem})
    : problem = null,
      refusal = null;

  /// The decision did not reach the service.
  const ConflictAnswer.failed(SyncProblem this.problem)
    : refusal = null,
      refreshProblem = null;

  /// The service answered but did not accept the decision, so the conflict is
  /// still open. [refusal] says why in words.
  const ConflictAnswer.notAccepted(String this.refusal)
    : problem = null,
      refreshProblem = null;

  /// Why the decision could not be sent.
  final SyncProblem? problem;

  /// Why the service did not accept the decision.
  final String? refusal;

  /// Why the sync after an accepted decision failed.
  final SyncProblem? refreshProblem;

  bool get resolved => problem == null && refusal == null;

  @override
  List<Object?> get props => [problem, refusal, refreshProblem];
}
