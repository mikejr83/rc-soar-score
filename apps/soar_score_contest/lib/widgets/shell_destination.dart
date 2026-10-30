import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// The name of a rail destination; [of] is its text in the app's language.
enum ShellDestinationName {
  contests,
  participants,
  roles,
  landings,
  workspace,
  configuration,
  matrix,
  scoring,
  reports,
  sync;

  String of(AppLocalizations l10n) => switch (this) {
    contests => l10n.shellNavContests,
    participants => l10n.shellNavParticipants,
    roles => l10n.shellNavRoles,
    landings => l10n.shellNavLandings,
    workspace => l10n.shellNavWorkspace,
    configuration => l10n.shellNavConfiguration,
    matrix => l10n.shellNavMatrix,
    scoring => l10n.shellNavScoring,
    reports => l10n.shellNavReports,
    sync => l10n.shellNavSync,
  };
}

/// One navigation-rail destination in the application shell. [location] is
/// `null` for destinations whose route does not exist yet; selecting one
/// shows the not-wired-up dialog.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.location,
  });

  final ShellDestinationName label;
  final IconData icon;
  final IconData selectedIcon;
  final String? location;

  /// Whether [path] is this destination's page or a page below it.
  /// Unwired destinations never match.
  bool matches(String path) {
    final location = this.location;
    return location != null &&
        (path == location || path.startsWith('$location/'));
  }
}
