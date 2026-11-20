import 'package:material_ui/material_ui.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/workspace/workspace_control.dart';
import 'control_card_body.dart';

/// The archive card. The contest actions API has no archive or unarchive
/// action yet, so the button is disabled and says why.
class ArchiveControlCard extends StatelessWidget {
  const ArchiveControlCard({super.key, required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ControlCardBody(
      control: WorkspaceControl.archive,
      current: contest.localArchive
          ? l10n.workspaceArchiveArchived
          : l10n.workspaceArchiveNotArchived,
      scope: l10n.workspaceArchiveScope,
      disabledReason: l10n.workspaceArchiveUnavailable,
      button: FilledButton.tonalIcon(
        key: const ValueKey('control-archive'),
        onPressed: null,
        icon: const Icon(Icons.archive),
        label: Text(l10n.workspaceArchiveButton),
      ),
    );
  }
}
