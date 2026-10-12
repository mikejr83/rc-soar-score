import 'next_step_action.dart';
import 'next_step_target.dart';

/// The buttons the steps share.
abstract final class NextStepActions {
  static const openConfiguration = NextStepAction(
    label: 'Open Configuration',
    target: NextStepTarget.configuration,
  );

  static const openParticipants = NextStepAction(
    label: 'Open Participants',
    target: NextStepTarget.participants,
  );

  static const goToMatrix = NextStepAction(
    label: 'Go to Matrix',
    target: NextStepTarget.matrix,
  );

  static const unlock = NextStepAction(
    label: 'Unlock administration',
    target: NextStepTarget.unlock,
    busyLabel: 'Unlocking…',
  );

  static const completeContest = NextStepAction(
    label: 'Complete contest…',
    target: NextStepTarget.completeDialog,
  );

  static const notYet = NextStepAction(
    label: 'Not yet',
    target: NextStepTarget.dismissSuggestion,
  );

  /// Opens scoring at [round], [group] (1 is group A) with [label].
  static NextStepAction scoring(String label, {int? round, int? group}) =>
      NextStepAction(
        label: label,
        target: NextStepTarget.scoring,
        round: round,
        group: group,
      );
}
