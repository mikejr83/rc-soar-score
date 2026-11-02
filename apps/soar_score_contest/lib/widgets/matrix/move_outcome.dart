import 'package:soar_score_core/soar_score_core.dart';

/// What the move dialog ended with.
sealed class MoveOutcome {
  const MoveOutcome();
}

/// The server moved the pilot; [matrix] is the matrix after the move.
class PilotMoved extends MoveOutcome {
  const PilotMoved(this.matrix);

  final CurrentMatrix matrix;
}

/// The matrix or the contest changed under the dialog: reload the page.
class MoveNeedsReload extends MoveOutcome {
  const MoveNeedsReload();
}
