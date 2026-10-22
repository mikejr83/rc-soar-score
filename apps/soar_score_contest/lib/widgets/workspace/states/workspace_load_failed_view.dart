import 'package:flutter/material.dart';

import '../../page_states/page_state_view.dart';

/// The workspace when the contest could not be loaded and there is no local
/// copy to show.
class WorkspaceLoadFailedView extends StatelessWidget {
  const WorkspaceLoadFailedView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  /// Why it failed, in the server's words when it sent any.
  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => PageStateView.unavailable(
    title: "Couldn't load this contest",
    body: '$message Nothing has changed.',
    primary: PageStateAction(
      key: const ValueKey('workspace-state-action'),
      label: 'Try again',
      onPressed: onRetry,
    ),
  );
}
