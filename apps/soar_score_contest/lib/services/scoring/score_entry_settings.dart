import 'package:equatable/equatable.dart';

/// The contest settings the score entry screen follows: the working time and
/// what a motor restart does.
class ScoreEntrySettings extends Equatable {
  const ScoreEntrySettings({
    this.workingTimeSeconds = 600,
    this.motorRestartMode = 'allowed',
  });

  /// Reads the F5J options of a configuration's `discipline` map, with the
  /// official defaults for anything not set.
  factory ScoreEntrySettings.fromDiscipline(Map<String, Object?>? discipline) {
    final time = discipline?['working_time'];
    final mode = discipline?['motor_restart_mode'];
    return ScoreEntrySettings(
      workingTimeSeconds: time is num && time > 0 ? time.toInt() : 600,
      motorRestartMode: mode is String ? mode : 'allowed',
    );
  }

  final int workingTimeSeconds;

  /// `allowed`, `non_droppable` or `not_allowed`.
  final String motorRestartMode;

  bool get restartsAllowed => motorRestartMode != 'not_allowed';
  bool get restartsNonDroppable => motorRestartMode == 'non_droppable';

  /// Launch heights above this ask "Is this correct?".
  int get unusualHeight => 300;

  @override
  List<Object?> get props => [workingTimeSeconds, motorRestartMode];
}
