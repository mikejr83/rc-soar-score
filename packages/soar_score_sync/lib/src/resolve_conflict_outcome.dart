import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'sync_failure_kind.dart';

/// What happened to a conflict decision sent with `SyncEngine.resolveConflict`.
class ResolveConflictOutcome {
  const ResolveConflictOutcome({this.failure, this.result});

  /// Why the decision could not be sent, or why the follow-up sync failed.
  final SyncFailureKind? failure;

  /// The service's answer to the decision. The service can answer a
  /// successful request with a rejection, a conflict or a skip.
  final SyncMutationResult? result;

  /// Whether the service accepted the decision. Only then is the conflict
  /// resolved; a failed follow-up sync does not undo an accepted decision.
  bool get accepted => result?.outcome == MutationOutcome.accepted;

  /// Why the service did not accept the decision, when it answered.
  SyncReasonCode? get reason => result?.reason;
}
