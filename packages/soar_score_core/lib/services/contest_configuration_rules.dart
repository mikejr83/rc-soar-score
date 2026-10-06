import 'dart:convert';

import '../enums/admin_lock.dart';
import '../enums/lifecycle_state.dart';
import '../errors/contest_state_error.dart';
import '../models/contest/contest.dart';
import '../models/contest/contest_configuration_revision.dart';

/// What the contest's state allows when a new configuration revision is
/// saved, from `plan/architecture-requirements/contest-state-and-transitions.md`.
///
/// Pure: it returns the contest as it is after the change and never stores
/// it.
abstract final class ContestConfigurationRules {
  /// The contest after saving [next], which follows [previous] (null for the
  /// first revision), stamped [now].
  ///
  /// - A locked or `Completed` contest takes no configuration change.
  /// - `Created` becomes `Configuring`.
  /// - `Ready` goes back to `Configuring` when the change invalidates the
  ///   matrix (teams, team protection, draw mode, preliminary rounds or lanes
  ///   changed), and stays `Ready` otherwise.
  /// - `Running` fixes the teams, roles, draw, lanes, participant numbers,
  ///   discipline settings and landing table. Only the derived-score options
  ///   (and reporting options) may change.
  ///
  /// Throws a [ContestStateError] when the state does not allow the change.
  static Contest apply(
    Contest contest,
    ContestConfigurationRevision? previous,
    ContestConfigurationRevision next,
    DateTime now,
  ) {
    if (contest.adminLock == AdminLock.locked) {
      throw ContestStateError(
        'contest_locked',
        'The contest is locked; unlock it to change its configuration.',
      );
    }
    switch (contest.lifecycleState) {
      case LifecycleState.completed:
        throw ContestStateError(
          'configuration_closed',
          'A Completed contest keeps its configuration.',
        );
      case LifecycleState.created:
        return contest.copyWithState(
          lifecycleState: LifecycleState.configuring,
          updatedAt: now,
        );
      case LifecycleState.configuring:
        return contest.copyWithState(updatedAt: now);
      case LifecycleState.ready:
        final invalidates = previous != null && _matrixChanged(previous, next);
        return contest.copyWithState(
          lifecycleState: invalidates ? LifecycleState.configuring : null,
          updatedAt: now,
        );
      case LifecycleState.running:
        if (previous != null) _requireRunningChangesAllowed(previous, next);
        return contest.copyWithState(updatedAt: now);
    }
  }

  static bool _matrixChanged(
    ContestConfigurationRevision previous,
    ContestConfigurationRevision next,
  ) {
    final a = previous.config.coreOptions;
    final b = next.config.coreOptions;
    return a.teamsEnabled != b.teamsEnabled ||
        a.teamProtection != b.teamProtection ||
        a.drawMode != b.drawMode ||
        a.preliminaryRounds != b.preliminaryRounds ||
        a.laneMode != b.laneMode;
  }

  static void _requireRunningChangesAllowed(
    ContestConfigurationRevision previous,
    ContestConfigurationRevision next,
  ) {
    final fixed = <String>[];
    final a = previous.config.coreOptions;
    final b = next.config.coreOptions;
    void check(String name, Object? before, Object? after) {
      if (before != after) fixed.add(name);
    }

    check('teams_enabled', a.teamsEnabled, b.teamsEnabled);
    check('team_protection', a.teamProtection, b.teamProtection);
    check('roles_enabled', a.rolesEnabled, b.rolesEnabled);
    check('draw_mode', a.drawMode, b.drawMode);
    check('preliminary_rounds', a.preliminaryRounds, b.preliminaryRounds);
    check('lane_mode', a.laneMode, b.laneMode);
    check(
      'participant_numbers_enabled',
      a.participantNumbersEnabled,
      b.participantNumbersEnabled,
    );
    if (_canonical(previous.config.discipline) !=
        _canonical(next.config.discipline)) {
      fixed.add('the discipline settings');
    }
    if (previous.landingTableId != next.landingTableId) {
      fixed.add('the landing table');
    }
    if (fixed.isNotEmpty) {
      throw ContestStateError(
        'configuration_fixed',
        'A Running contest cannot change ${fixed.join(', ')}.',
      );
    }
  }

  /// A comparable form of a settings map, independent of key order.
  static String _canonical(Map<String, Object?> map) => jsonEncode(
    Map.fromEntries(
      map.entries.toList()..sort((x, y) => x.key.compareTo(y.key)),
    ),
  );
}
