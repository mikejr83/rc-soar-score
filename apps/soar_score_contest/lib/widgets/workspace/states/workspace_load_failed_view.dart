import 'package:flutter/material.dart';

import 'workspace_state_message.dart';

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
  Widget build(BuildContext context) => WorkspaceStateMessage(
    icon: Icons.error_outline,
    title: "Couldn't load this contest",
    body: '$message Nothing has changed.',
    actionLabel: 'Try again',
    onAction: onRetry,
  );
}
