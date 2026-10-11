/// A control card inside the workspace `controls` section.
enum WorkspaceControl {
  lifecycle('lifecycle'),
  scoring('scoring'),
  results('results'),
  administration('administration'),
  publication('publication'),
  archive('archive');

  const WorkspaceControl(this.id);

  /// Stable id for deep links (`#lifecycle`) and widget keys.
  final String id;
}
