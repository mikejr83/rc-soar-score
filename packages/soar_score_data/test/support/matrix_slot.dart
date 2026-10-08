import 'package:soar_score_core/soar_score_core.dart' as core;

/// An assignment of the first round and the participation it belongs to.
class MatrixSlot {
  const MatrixSlot(this.assignmentId, this.participationId);

  final core.Id assignmentId;
  final core.Id participationId;
}
