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

/// The selected contest's id when [path] is a contest-scoped route, else
/// `null`. The New Contest wizard ([newContestPath]) is not a contest.
String? contestIdFor(String path) {
  if (!path.startsWith('$contestsPath/') ||
      path == newContestPath ||
      path.startsWith('$newContestPath/')) {
    return null;
  }
  final segments = path
      .substring(contestsPath.length)
      .split('/')
      .where((segment) => segment.isNotEmpty);
  return segments.isEmpty ? null : segments.first;
}

ShellScope shellScopeFor(String path) =>
    contestIdFor(path) == null ? ShellScope.system : ShellScope.contest;

/// The rail destinations for [path]. Matrix, scoring and reports only make
/// sense for a selected contest, so they appear only in the contest scope.
List<ShellDestination> shellDestinationsFor(String path) {
  final contestId = contestIdFor(path);
  if (contestId == null) {
    return const [
      ShellDestination(
        label: 'Contests',
        icon: Icons.event_outlined,
        selectedIcon: Icons.event,
        location: homePath,
      ),
      ShellDestination(
        label: 'Participants',
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups,
        location: participantsPath,
      ),
      ShellDestination(
        label: 'Roles',
        icon: Icons.badge_outlined,
        selectedIcon: Icons.badge,
        location: rolesPath,
      ),
      ShellDestination(
        label: 'Landings',
        icon: Icons.track_changes,
        selectedIcon: Icons.track_changes,
        location: landingsPath,
      ),
    ];
  }
  return [
    ShellDestination(
      label: 'Workspace',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      location: contestWorkspacePath(contestId),
    ),
    const ShellDestination(
      label: 'Matrix',
      icon: Icons.grid_on_outlined,
      selectedIcon: Icons.grid_on,
    ),
    const ShellDestination(
      label: 'Scoring',
      icon: Icons.edit_note_outlined,
      selectedIcon: Icons.edit_note,
    ),
    const ShellDestination(
      label: 'Reports',
      icon: Icons.assessment_outlined,
      selectedIcon: Icons.assessment,
    ),
  ];
}
