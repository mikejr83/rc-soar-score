import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Where the fix for a [DrawBlocker] is.
enum BlockerFix { configuration, workspace, participants }

/// One reason the draw is not allowed: an icon, one sentence and, when there
/// is a fix, a link to it. The matrix page and the configuration page show
/// the same reasons.
class DrawBlocker {
  const DrawBlocker({
    required this.icon,
    required this.text,
    this.linkLabel,
    this.fix,
  });

  final IconData icon;
  final String text;
  final String? linkLabel;
  final BlockerFix? fix;
}

/// Whether `Draw matrix` can be used, and why not
/// (`plan/ui/contest-administration/contest-workspace.md` and `matrix.md`).
///
/// This is the one set of enabling rules for both the configuration page's
/// button and the matrix page's form.
class DrawReadiness {
  const DrawReadiness(this.blockers);

  /// Evaluates the rules for [contest].
  ///
  /// [configurationProblem] says what is wrong with the configuration, or is
  /// `null` when it is usable. [scoringPilots] counts the pilots who fly (not
  /// non-fliers or retired pilots); [matrixDrawn] is true once a matrix
  /// exists, which is redrawn from the matrix page instead. [forRounds] is
  /// for adding rounds or redrawing, which need a drawn matrix.
  factory DrawReadiness.evaluate({
    required Contest contest,
    required String? configurationProblem,
    required int scoringPilots,
    required bool matrixDrawn,
    bool forRounds = false,
  }) => DrawReadiness([
    // Adding rounds and redrawing are allowed after the first draw, so the
    // lifecycle and lock rules that only apply to the first draw are left
    // out; the matrix page checks the ones that apply to rounds.
    if (forRounds)
      ...const <DrawBlocker>[]
    else if (contest.lifecycleState == LifecycleState.completed)
      const DrawBlocker(
        icon: Icons.flag_outlined,
        text: 'The contest is completed. A completed contest can’t be drawn.',
      )
    else if (contest.lifecycleState == LifecycleState.created)
      const DrawBlocker(
        icon: Icons.save_outlined,
        text: 'Save the configuration first.',
        linkLabel: 'Open Configuration',
        fix: BlockerFix.configuration,
      )
    else if (contest.lifecycleState != LifecycleState.configuring)
      const DrawBlocker(
        icon: Icons.flag_outlined,
        text:
            'The contest is no longer being configured, so the matrix can’t '
            'be drawn.',
        linkLabel: 'Open Workspace',
        fix: BlockerFix.workspace,
      ),
    if (!forRounds && contest.adminLock == AdminLock.locked)
      const DrawBlocker(
        icon: Icons.lock_outline,
        text: 'The contest is locked, so the matrix can’t be drawn.',
        linkLabel: 'Unlock in Configuration',
        fix: BlockerFix.configuration,
      ),
    if (configurationProblem != null)
      DrawBlocker(
        icon: Icons.rule,
        text: configurationProblem,
        linkLabel: 'Fix in Configuration',
        fix: BlockerFix.configuration,
      ),
    if (scoringPilots < 2)
      DrawBlocker(
        icon: Icons.group_outlined,
        text:
            'Drawing needs at least 2 scoring pilots. This contest has '
            '$scoringPilots.',
        linkLabel: 'Add pilots in Participants',
        fix: BlockerFix.participants,
      ),
    if (matrixDrawn && !forRounds)
      const DrawBlocker(
        icon: Icons.grid_view,
        text: 'The matrix is already drawn.',
      ),
  ]);

  /// Everything that currently prevents the draw, most important first;
  /// empty when it is allowed.
  final List<DrawBlocker> blockers;

  bool get enabled => blockers.isEmpty;

  /// The sentences of [blockers].
  List<String> get reasons => [for (final blocker in blockers) blocker.text];

  /// The most important blocker, or `null` when the draw is allowed.
  DrawBlocker? get first => blockers.isEmpty ? null : blockers.first;
}
