/// A panel the user can hide or minimize, and whether it starts open.
///
/// Register each one in [collapsibleAreas] so that remembering the choice and
/// "Reset to defaults" cover it without further wiring.
class CollapsibleArea {
  const CollapsibleArea({required this.id, this.defaultOpen = true});

  /// Stable name stored with the choice. Never reuse or rename one.
  final String id;

  /// Whether the area is open when the user has not chosen.
  final bool defaultOpen;
}

/// The matrix page's fairness summary ("Hide summary").
const CollapsibleArea matrixSummaryArea = CollapsibleArea(id: 'matrix_summary');

/// Every collapsible area in the app.
const List<CollapsibleArea> collapsibleAreas = [matrixSummaryArea];
