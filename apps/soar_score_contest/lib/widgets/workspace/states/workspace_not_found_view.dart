import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../page_states/page_state_view.dart';

/// The workspace when the route's id does not match a contest.
class WorkspaceNotFoundView extends StatelessWidget {
  const WorkspaceNotFoundView({super.key, required this.onBack});

  /// Goes back to the contest list.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageStateView.notFound(
      title: l10n.workspaceNotFoundTitle,
      body: l10n.workspaceNotFoundBody,
      primary: PageStateAction(
        key: const ValueKey('workspace-state-action'),
        label: l10n.workspaceNotFoundBack,
        onPressed: onBack,
      ),
    );
  }
}
