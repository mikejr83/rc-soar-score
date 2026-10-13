import 'package:equatable/equatable.dart';

import 'sync_problem.dart';

/// What came of sending the director's decision for a conflict.
class ConflictAnswer extends Equatable {
  const ConflictAnswer.resolved() : problem = null, refusal = null;

  /// The decision did not reach the service.
  const ConflictAnswer.failed(SyncProblem this.problem) : refusal = null;

  /// The service answered but did not accept the decision, so the conflict is
  /// still open. [refusal] says why in words.
  const ConflictAnswer.notAccepted(String this.refusal) : problem = null;

  /// Why the decision could not be sent.
  final SyncProblem? problem;

  /// Why the service did not accept the decision.
  final String? refusal;

  bool get resolved => problem == null && refusal == null;

  @override
  List<Object?> get props => [problem, refusal];
}
