import 'package:soar_score_core/soar_score_core.dart';

/// Whether `Draw matrix` can be used, and why not
/// (`plan/ui/contest-administration/contest-workspace.md`).
class DrawReadiness {
  const DrawReadiness(this.reasons);

  /// Evaluates the rules for [contest].
  ///
  /// [hasValidConfiguration] is false until a configuration has been saved.
  /// [scoringPilots] counts the pilots who fly (not non-fliers or retired
  /// pilots); [matrixDrawn] is true once a matrix exists, which is redrawn
  /// from the matrix page instead.
  factory DrawReadiness.evaluate({
    required Contest contest,
    required bool hasValidConfiguration,
    required int scoringPilots,
    required bool matrixDrawn,
  }) => DrawReadiness([
    if (contest.lifecycleState == LifecycleState.completed)
      'The contest is completed.'
    else if (contest.lifecycleState == LifecycleState.created)
      'Save the configuration first.'
    else if (contest.lifecycleState != LifecycleState.configuring)
      'The contest is no longer being configured.',
    if (contest.adminLock == AdminLock.locked) 'Administration is locked.',
    if (!hasValidConfiguration) 'The configuration is not valid yet.',
    if (scoringPilots < 2) 'At least two scoring pilots are needed.',
    if (matrixDrawn) 'The matrix is already drawn.',
  ]);

  /// Everything that currently prevents the draw; empty when it is allowed.
  final List<String> reasons;

  bool get enabled => reasons.isEmpty;
}
