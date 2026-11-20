import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageStateView.unavailable(
      title: l10n.workspaceLoadFailedTitle,
      body: l10n.workspaceLoadFailedBody(message),
      primary: PageStateAction(
        key: const ValueKey('workspace-state-action'),
        label: l10n.workspaceLoadFailedRetry,
        onPressed: onRetry,
      ),
    );
  }
}
