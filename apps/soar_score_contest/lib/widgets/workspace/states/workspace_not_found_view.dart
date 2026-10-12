import 'package:flutter/material.dart';

import 'workspace_state_message.dart';

/// The workspace when the route's id does not match a contest.
class WorkspaceNotFoundView extends StatelessWidget {
  const WorkspaceNotFoundView({super.key, required this.onBack});

  /// Goes back to the contest list.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => WorkspaceStateMessage(
    icon: Icons.search_off,
    title: 'Contest not found',
    body:
        "This link doesn't match a contest on this device or the server. It "
        'may have been deleted, or the link is incomplete.',
    actionLabel: 'Back to Contests',
    onAction: onBack,
  );
}
