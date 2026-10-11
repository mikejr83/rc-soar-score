import 'package:soar_score_core/soar_score_core.dart';

import 'workspace_control.dart';
import 'workspace_section.dart';

/// Which workspace sections appear, in which column and order, and the order of
/// the control cards, for one lifecycle stage. Pure data: widgets render it and
/// never re-decide visibility.
class WorkspaceLayoutPlan {
  const WorkspaceLayoutPlan._({
    required this.main,
    required this.side,
    required this.single,
    required this.controls,
  });

  /// Main (left) column, wide layout.
  final List<WorkspaceSection> main;

  /// Side (right) column, wide layout.
  final List<WorkspaceSection> side;

  /// The one-column (narrow) order.
  final List<WorkspaceSection> single;

  /// Control cards inside the `controls` section, top to bottom.
  final List<WorkspaceControl> controls;

  /// [hasMatrix] is true once a matrix has been drawn; [hasAttentionItems] is
  /// true when the needs-attention list has at least one entry.
  factory WorkspaceLayoutPlan.of({
    required LifecycleState lifecycle,
    required bool hasMatrix,
    required bool hasAttentionItems,
  }) {
    final List<WorkspaceSection> main;
    final List<WorkspaceControl> controls;
    switch (lifecycle) {
      case LifecycleState.created:
      case LifecycleState.configuring:
      case LifecycleState.ready:
        main = [
          WorkspaceSection.nextStep,
          WorkspaceSection.checklist,
          if (hasMatrix) WorkspaceSection.progress,
          WorkspaceSection.activity,
        ];
        controls = const [
          WorkspaceControl.lifecycle,
          WorkspaceControl.scoring,
          WorkspaceControl.administration,
          WorkspaceControl.publication,
          WorkspaceControl.archive,
        ];
      case LifecycleState.running:
        main = const [
          WorkspaceSection.nextStep,
          WorkspaceSection.attention,
          WorkspaceSection.progress,
          WorkspaceSection.activity,
        ];
        controls = const [
          WorkspaceControl.scoring,
          WorkspaceControl.results,
          WorkspaceControl.publication,
          WorkspaceControl.administration,
          WorkspaceControl.lifecycle,
          WorkspaceControl.archive,
        ];
      case LifecycleState.completed:
        main = [
          WorkspaceSection.nextStep,
          WorkspaceSection.progress,
          if (hasAttentionItems) WorkspaceSection.attention,
          WorkspaceSection.activity,
        ];
        controls = const [
          WorkspaceControl.publication,
          WorkspaceControl.lifecycle,
          WorkspaceControl.scoring,
          WorkspaceControl.administration,
          WorkspaceControl.archive,
        ];
    }
    const side = [WorkspaceSection.controls, WorkspaceSection.facts];
    return WorkspaceLayoutPlan._(
      main: List.unmodifiable(main),
      side: side,
      single: List.unmodifiable([
        ...main.where((s) => s != WorkspaceSection.activity),
        ...side,
        WorkspaceSection.activity,
      ]),
      controls: List.unmodifiable(controls),
    );
  }
}
