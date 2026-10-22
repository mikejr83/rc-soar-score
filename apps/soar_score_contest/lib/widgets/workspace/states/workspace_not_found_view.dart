import 'package:flutter/material.dart';

import '../../page_states/page_state_view.dart';

/// The workspace when the route's id does not match a contest.
class WorkspaceNotFoundView extends StatelessWidget {
  const WorkspaceNotFoundView({super.key, required this.onBack});

  /// Goes back to the contest list.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => PageStateView.notFound(
    title: 'Contest not found',
    body:
        "This link doesn't match a contest on this device or the server. It "
        'may have been deleted, or the link is incomplete.',
    primary: PageStateAction(
      key: const ValueKey('workspace-state-action'),
      label: 'Back to Contests',
      onPressed: onBack,
    ),
  );
}
