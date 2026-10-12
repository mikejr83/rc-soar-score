import 'package:flutter/material.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_error_text.dart';

/// Applies a contest action in place and tells the director what happened.
///
/// A success shows [done] with an Undo button that applies [undo]; a
/// rejected or stale transition (409) leaves the page as it is and shows the
/// server's message with a Refresh button. The next-step card uses it now and
/// the control cards (#250) will too.
class ContestActionRunner {
  ContestActionRunner({
    required this.client,
    required this.messenger,
    required this.refresh,
  });

  final ApiClient client;
  final ScaffoldMessengerState messenger;

  /// Loads the contest and the facts again after a change.
  final Future<void> Function() refresh;

  /// Applies [action] to [contest]. Returns the updated contest, or `null`
  /// when the action was rejected.
  Future<Contest?> run(
    Contest contest,
    ContestAction action, {
    required String done,
    required ContestAction undo,
  }) async {
    final Contest updated;
    try {
      updated = await client.applyContestAction(
        contest.id,
        ContestActionRequest(action: action, baseRevision: contest.revision),
      );
    } on Object catch (error) {
      _rejected(error);
      return null;
    }
    await refresh();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(done),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _undo(updated, undo),
          ),
        ),
      );
    return updated;
  }

  Future<void> _undo(Contest contest, ContestAction undo) async {
    try {
      await client.applyContestAction(
        contest.id,
        ContestActionRequest(action: undo, baseRevision: contest.revision),
      );
    } on Object catch (error) {
      _rejected(error);
      return;
    }
    await refresh();
  }

  void _rejected(Object error) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(apiErrorText(error)),
          action: SnackBarAction(label: 'Refresh', onPressed: refresh),
        ),
      );
  }
}
