import 'package:flutter/widgets.dart';

import '../../services/workspace/workspace_control_target.dart';
import 'workspace_focus_controller.dart';

/// The connection between the shell's status panel and the workspace page.
///
/// The shell owns it and offers it to its page; a mounted workspace
/// [attach]es its controller, so the panel can tell whether it is already on
/// the workspace.
class WorkspaceFocusLink {
  WorkspaceFocusController? _active;

  /// True while a workspace page is mounted under the shell.
  bool get isAttached => _active != null;

  void attach(WorkspaceFocusController controller) {
    _active = controller;
  }

  void detach(WorkspaceFocusController controller) {
    if (_active == controller) {
      _active = null;
    }
  }

  /// Focuses [target] on the attached workspace; `false` when there is none
  /// or the control is not on it yet.
  bool focus(WorkspaceControlTarget target, {required bool animate}) =>
      _active?.focus(target, animate: animate) ?? false;
}

/// Offers a [WorkspaceFocusLink] to the page below the shell.
class WorkspaceFocusLinkScope extends InheritedWidget {
  const WorkspaceFocusLinkScope({
    super.key,
    required this.link,
    required super.child,
  });

  final WorkspaceFocusLink link;

  /// The nearest link, or `null` outside a shell.
  static WorkspaceFocusLink? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<WorkspaceFocusLinkScope>()?.link;

  @override
  bool updateShouldNotify(WorkspaceFocusLinkScope oldWidget) =>
      link != oldWidget.link;
}
