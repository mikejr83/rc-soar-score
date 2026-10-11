import 'package:flutter/widgets.dart';

/// What the workspace page offers to the widgets inside it.
class WorkspaceScope extends InheritedWidget {
  const WorkspaceScope({
    super.key,
    required this.refresh,
    required this.announce,
    required this.readOnly,
    required super.child,
  });

  /// Reloads the contest (and, later, the workspace facts) after an in-place
  /// action.
  final Future<void> Function() refresh;

  /// Says [message] politely to assistive technology, for example the next
  /// step's new title after an action.
  final void Function(String message) announce;

  /// True for a completed contest.
  final bool readOnly;

  static WorkspaceScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WorkspaceScope>();
    assert(scope != null, 'No WorkspaceScope above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(WorkspaceScope oldWidget) =>
      readOnly != oldWidget.readOnly;
}
