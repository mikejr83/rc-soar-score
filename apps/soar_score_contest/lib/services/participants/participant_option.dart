import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

/// A participant option in step 3 of the New Contest wizard. Each one adds
/// columns to the Participants step, and says so.
enum ParticipantOption {
  teams,
  pilotNumbers,
  classes,
  roles,
  models;

  IconData get icon => switch (this) {
    teams => Icons.diversity_3,
    pilotNumbers => Icons.pin_outlined,
    classes => Icons.workspace_premium_outlined,
    roles => Icons.badge_outlined,
    models => Icons.flight,
  };

  /// The user-visible title for this option.
  String title(AppLocalizations l10n) => switch (this) {
    teams => l10n.wizardOptionTeamsTitle,
    pilotNumbers => l10n.wizardOptionPilotNumbersTitle,
    classes => l10n.wizardOptionClassesTitle,
    roles => l10n.wizardOptionRolesTitle,
    models => l10n.wizardOptionModelsTitle,
  };

  /// The user-visible description for this option.
  String description(AppLocalizations l10n) => switch (this) {
    teams => l10n.wizardOptionTeamsDesc,
    pilotNumbers => l10n.wizardOptionPilotNumbersDesc,
    classes => l10n.wizardOptionClassesDesc,
    roles => l10n.wizardOptionRolesDesc,
    models => l10n.wizardOptionModelsDesc,
  };

  /// How the option changes the Participants step.
  String effect(AppLocalizations l10n) => switch (this) {
    teams => l10n.wizardOptionTeamsEffect,
    pilotNumbers => l10n.wizardOptionPilotNumbersEffect,
    classes => l10n.wizardOptionClassesEffect,
    roles => l10n.wizardOptionRolesEffect,
    models => l10n.wizardOptionModelsEffect,
  };

  /// Shown under the option while it is on.
  String? note(AppLocalizations l10n) => switch (this) {
    pilotNumbers => l10n.wizardOptionPilotNumbersNote,
    models => l10n.wizardOptionModelsNote,
    _ => null,
  };
}
