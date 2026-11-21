import '../../l10n/app_localizations.dart';

/// The state of one wizard step, shown by shape, icon and text (never color
/// alone).
enum WizardStepStatus {
  complete,
  current,
  currentNeedsAttention,
  needsAttention,
  visited,
  notStarted;

  String label(AppLocalizations l10n) => switch (this) {
    WizardStepStatus.complete => l10n.wizardStepComplete,
    WizardStepStatus.current => l10n.wizardStepCurrent,
    WizardStepStatus.currentNeedsAttention =>
      l10n.wizardStepCurrentNeedsAttention,
    WizardStepStatus.needsAttention => l10n.wizardStepNeedsAttention,
    WizardStepStatus.visited => l10n.wizardStepVisited,
    WizardStepStatus.notStarted => l10n.wizardStepNotStarted,
  };

  bool get isCurrent => this == current || this == currentNeedsAttention;

  bool get hasError => this == needsAttention || this == currentNeedsAttention;

  /// Steps not reached yet cannot be jumped to.
  bool get locked => this == notStarted;
}

/// One entry of the wizard's step navigation.
class WizardStepEntry {
  const WizardStepEntry({
    required this.number,
    required this.title,
    required this.status,
  });

  final int number;
  final String title;
  final WizardStepStatus status;

  String semanticLabel(AppLocalizations l10n, int total) =>
      l10n.wizardStepOf(number, total, title);
}
