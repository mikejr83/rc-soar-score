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

/// The first-draw form's "Advanced" section (random seed and friends).
const CollapsibleArea drawAdvancedArea = CollapsibleArea(
  id: 'draw_advanced',
  defaultOpen: false,
);

/// The matrix page's "Draw details" under the fairness summary.
const CollapsibleArea drawDetailsArea = CollapsibleArea(
  id: 'draw_details',
  defaultOpen: false,
);

/// The navigation rail's expanded state (wide windows only).
const CollapsibleArea shellRailArea = CollapsibleArea(
  id: 'shell_rail',
  defaultOpen: false,
);

/// The landing table entries table on the configuration page.
const CollapsibleArea landingEntriesArea = CollapsibleArea(
  id: 'landing_entries',
  defaultOpen: false,
);

/// Every collapsible area in the app.
const List<CollapsibleArea> collapsibleAreas = [
  matrixSummaryArea,
  drawAdvancedArea,
  drawDetailsArea,
  shellRailArea,
  landingEntriesArea,
];
