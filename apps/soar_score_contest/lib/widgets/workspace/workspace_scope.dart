import 'package:flutter/widgets.dart';

import '../../services/workspace/workspace_facts.dart';

/// What the workspace page offers to the widgets inside it.
class WorkspaceScope extends InheritedWidget {
  const WorkspaceScope({
    super.key,
    required this.refresh,
    required this.announce,
    required this.readOnly,
    required this.reloadFacts,
    this.facts,
    this.factsFailed = false,
    required super.child,
  });

  /// Reloads the contest (and, later, the workspace facts) after an in-place
  /// action.
  final Future<void> Function() refresh;

  /// Says [message] politely to assistive technology, for example the next
  /// step's new title after an action.
  final void Function(String message) announce;

  /// Loads the workspace facts again without touching the contest, for a
  /// Retry after a failed read.
  final VoidCallback reloadFacts;

  /// True when loading the facts failed; [facts] is then `null`.
  final bool factsFailed;

  /// What the workspace knows about the contest beyond the contest itself;
  /// `null` until loaded or when loading failed.
  final WorkspaceFacts? facts;

  /// True for a completed contest.
  final bool readOnly;

  static WorkspaceScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WorkspaceScope>();
    assert(scope != null, 'No WorkspaceScope above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(WorkspaceScope oldWidget) =>
      readOnly != oldWidget.readOnly ||
      facts != oldWidget.facts ||
      factsFailed != oldWidget.factsFailed;
}
