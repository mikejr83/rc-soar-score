import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../services/workspace/workspace_control.dart';
import 'control_card_body.dart';

/// The archive card. The contest actions API has no archive or unarchive
/// action yet, so the button is disabled and says why.
class ArchiveControlCard extends StatelessWidget {
  const ArchiveControlCard({super.key, required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context) => ControlCardBody(
    control: WorkspaceControl.archive,
    current: contest.localArchive ? 'Archived' : 'Not archived',
    scope: 'Archiving moves a contest out of the way on this installation.',
    disabledReason:
        'Archiving is not available yet: the server has no '
        'archive action.',
    button: FilledButton.tonalIcon(
      key: const ValueKey('control-archive'),
      onPressed: null,
      icon: const Icon(Icons.archive),
      label: const Text('Archive contest'),
    ),
  );
}
