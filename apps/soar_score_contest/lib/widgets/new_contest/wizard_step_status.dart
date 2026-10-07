/// The state of one wizard step, shown by shape, icon and text (never color
/// alone).
enum WizardStepStatus {
  complete('Complete'),
  current('Current step'),
  currentNeedsAttention('Current · needs attention'),
  needsAttention('Needs attention'),
  visited('Visited'),
  notStarted('Not started');

  const WizardStepStatus(this.label);

  final String label;

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

  String get semanticLabel => 'Step $number, $title, ${status.label}';
}
