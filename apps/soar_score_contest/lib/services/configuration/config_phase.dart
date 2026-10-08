import 'package:soar_score_core/soar_score_core.dart';

/// Where a contest is in its life, as far as editing its configuration is
/// concerned (`plan/architecture-requirements/contest-state-and-transitions.md`).
enum ConfigPhase {
  /// No matrix yet: everything can change freely.
  before,

  /// A matrix is drawn: structural changes make it out of date.
  drawn,

  /// Scoring has started: structure, discipline options and the landing table
  /// are fixed, and scoring changes recalculate results.
  running,

  /// The configuration is read-only.
  completed;

  static ConfigPhase of(Contest contest, {required bool matrixDrawn}) =>
      switch (contest.lifecycleState) {
        LifecycleState.completed => completed,
        LifecycleState.running => running,
        LifecycleState.ready => drawn,
        LifecycleState.created ||
        LifecycleState.configuring => matrixDrawn ? drawn : before,
      };

  bool get isDrawn => this == drawn;
  bool get isRunning => this == running;
}
