import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../api_client_provider.dart';
import '../../../services/workspace/controls/contest_transition.dart';
import '../next_step/contest_action_runner.dart';
import '../workspace_scope.dart';
import 'complete_dialog.dart';
import 'lock_dialog.dart';

/// Asks the director to confirm [transition] when it needs it (lock and
/// complete); resolves to true at once for the others.
Future<bool> confirmTransition(
  BuildContext context,
  WorkspaceScope scope,
  ContestTransition transition,
) => switch (transition) {
  ContestTransition.lock => confirmLock(context),
  ContestTransition.complete => confirmComplete(context, facts: scope.facts),
  _ => Future.value(true),
};

/// Makes [transition] on [contest] in place with the contest actions API and
/// refreshes the page.
///
/// Returns the updated contest, or `null` when no API client was available or
/// the server rejected the change (the page then shows its stale banner or a
/// snackbar and stays as it was).
Future<Contest?> runTransition(
  BuildContext context,
  WorkspaceScope scope,
  Contest contest,
  ContestTransition transition,
) async {
  final client = apiClientOf(context);
  final messenger = ScaffoldMessenger.of(context);
  if (client == null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('No API client is available.')),
    );
    return null;
  }
  final runner = ContestActionRunner(
    client: client,
    messenger: messenger,
    refresh: scope.refresh,
    onStale: scope.reportStale,
  );
  return runner.run(
    contest,
    transition.action,
    what: transition.what,
    done: transition.done,
    undo: transition.undo,
  );
}
