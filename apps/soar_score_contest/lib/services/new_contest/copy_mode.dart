import '../../l10n/app_localizations.dart';

/// What the New Contest wizard copies from an existing contest (step 1).
///
/// Copying never brings scores, the flight matrix, publication history,
/// invitations, deletion state or audit history
/// (`plan/ui/contest-administration/new-contest-wizard.md`).
enum CopyMode {
  none,
  configuration,
  allPilots,
  selectedPilots;

  /// The user-visible label for this mode.
  String label(AppLocalizations l10n) => switch (this) {
    none => l10n.wizardCopyModeNone,
    configuration => l10n.wizardCopyModeConfiguration,
    allPilots => l10n.wizardCopyModeAllPilots,
    selectedPilots => l10n.wizardCopyModeSelectedPilots,
  };

  /// The user-visible description for this mode.
  String description(AppLocalizations l10n) => switch (this) {
    none => l10n.wizardCopyModeNoneDesc,
    configuration => l10n.wizardCopyModeConfigurationDesc,
    allPilots => l10n.wizardCopyModeAllPilotsDesc,
    selectedPilots => l10n.wizardCopyModeSelectedPilotsDesc,
  };

  /// Whether a source contest is needed.
  bool get usesSource => this != none;

  /// Whether pilots come along with the configuration.
  bool get copiesPilots => this == allPilots || this == selectedPilots;
}
