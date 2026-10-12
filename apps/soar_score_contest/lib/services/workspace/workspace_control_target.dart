import 'workspace_control.dart';

/// A control card on the workspace that the shell status panel can link to.
///
/// The fragment is the one in `…/workspace#administration`.
enum WorkspaceControlTarget {
  lifecycle('lifecycle', WorkspaceControl.lifecycle),
  scoring('scoring', WorkspaceControl.scoring),
  administration('administration', WorkspaceControl.administration);

  const WorkspaceControlTarget(this.fragment, this.control);

  final String fragment;
  final WorkspaceControl control;

  /// The target named by [fragment]; `null` for an empty or unknown one.
  static WorkspaceControlTarget? fromFragment(String? fragment) {
    for (final target in values) {
      if (target.fragment == fragment) {
        return target;
      }
    }
    return null;
  }
}
