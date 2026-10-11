/// A section of the contest workspace page.
enum WorkspaceSection {
  nextStep('next-step'),
  checklist('checklist'),
  attention('attention'),
  progress('progress'),
  controls('controls'),
  facts('facts'),
  activity('activity');

  const WorkspaceSection(this.id);

  /// Stable id for deep links and widget keys.
  final String id;
}
