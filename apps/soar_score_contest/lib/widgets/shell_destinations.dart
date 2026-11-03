import 'package:flutter/material.dart';

import '../router.dart';
import 'shell_destination.dart';

/// Which set of navigation the shell shows for a location.
enum ShellScope {
  /// System-level management: contest selection and the director's reusable
  /// data (main page, `plan/ui/contest-administration/main-page.md`).
  system,

  /// Administration of one selected contest (any route below
  /// [contestsPath]).
  contest,
}

ShellScope shellScopeFor(String path) =>
    contestIdFor(path) == null ? ShellScope.system : ShellScope.contest;

/// The rail destinations for [path]. Matrix, scoring and reports only make
/// sense for a selected contest, so they appear only in the contest scope.
/// Sync appears only when the build synchronizes ([showSync]).
List<ShellDestination> shellDestinationsFor(
  String path, {
  bool showSync = false,
}) {
  final contestId = contestIdFor(path);
  if (contestId == null) {
    return const [
      ShellDestination(
        label: ShellDestinationName.contests,
        icon: Icons.event_outlined,
        selectedIcon: Icons.event,
        location: homePath,
      ),
      ShellDestination(
        label: ShellDestinationName.participants,
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups,
        location: participantsPath,
      ),
      ShellDestination(
        label: ShellDestinationName.roles,
        icon: Icons.badge_outlined,
        selectedIcon: Icons.badge,
        location: rolesPath,
      ),
      ShellDestination(
        label: ShellDestinationName.landings,
        icon: Icons.track_changes,
        selectedIcon: Icons.track_changes,
        location: landingsPath,
      ),
    ];
  }
  return [
    ShellDestination(
      label: ShellDestinationName.workspace,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      location: contestWorkspacePath(contestId),
    ),
    ShellDestination(
      label: ShellDestinationName.configuration,
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
      location: contestConfigurationPath(contestId),
    ),
    ShellDestination(
      label: ShellDestinationName.participants,
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      location: contestParticipantsPath(contestId),
    ),
    ShellDestination(
      label: ShellDestinationName.matrix,
      icon: Icons.grid_on_outlined,
      selectedIcon: Icons.grid_on,
      location: contestMatrixPath(contestId),
    ),
    ShellDestination(
      label: ShellDestinationName.scoring,
      icon: Icons.edit_note_outlined,
      selectedIcon: Icons.edit_note,
      location: contestScoringPath(contestId),
    ),
    ShellDestination(
      label: ShellDestinationName.reports,
      icon: Icons.assessment_outlined,
      selectedIcon: Icons.assessment,
      location: contestReportsPath(contestId),
    ),
    if (showSync)
      ShellDestination(
        label: ShellDestinationName.sync,
        icon: Icons.sync_outlined,
        selectedIcon: Icons.sync,
        location: contestSyncPath(contestId),
      ),
  ];
}
