import 'package:flutter/material.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_error_text.dart';

/// Applies a contest action in place and tells the director what happened.
///
/// A success shows [done] with an Undo button that applies [undo]; a
/// rejected or stale transition (409) leaves the page as it is and shows the
/// server's message with a Refresh button. The next-step card and the control
/// cards both use it. A transition with no way back passes no `undo` and gets
/// no Undo button.
class ContestActionRunner {
  ContestActionRunner({
    required this.client,
    required this.messenger,
    required this.refresh,
    this.onStale,
  });

  final ApiClient client;
  final ScaffoldMessengerState messenger;

  /// Loads the contest and the facts again after a change.
  final Future<void> Function() refresh;

  /// Called with `what` when a transition is answered with 409 (a stale
  /// revision or a rejected transition), so the page can show its stale
  /// banner. Without it the rejection is a snackbar with Refresh.
  final void Function(String what)? onStale;

  /// Applies [action] to [contest]. Returns the updated contest, or `null`
  /// when the action was rejected.
  Future<Contest?> run(
    Contest contest,
    ContestAction action, {
    required String what,
    required String done,
    required ContestAction? undo,
  }) async {
    final Contest updated;
    try {
      updated = await client.applyContestAction(
        contest.id,
        ContestActionRequest(action: action, baseRevision: contest.revision),
      );
    } on Object catch (error) {
      _rejected(error, what);
      return null;
    }
    await refresh();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(done),
          // A snack bar with an action stays until dismissed unless told
          // otherwise; a confirmation is not worth a click to clear.
          persist: false,
          duration: const Duration(seconds: 8),
          action: undo == null
              ? null
              : SnackBarAction(
                  label: 'Undo',
                  onPressed: () => _undo(updated, undo, what),
                ),
        ),
      );
    return updated;
  }

  Future<void> _undo(Contest contest, ContestAction undo, String what) async {
    try {
      await client.applyContestAction(
        contest.id,
        ContestActionRequest(action: undo, baseRevision: contest.revision),
      );
    } on Object catch (error) {
      _rejected(error, what);
      return;
    }
    await refresh();
  }

  void _rejected(Object error, String what) {
    final stale = onStale;
    if (stale != null && error is ApiHttpError && error.statusCode == 409) {
      messenger.hideCurrentSnackBar();
      stale(what);
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(apiErrorText(error)),
          // A snack bar with an action stays until dismissed unless told
          // otherwise; a failure notice is not worth a click to clear.
          persist: false,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(label: 'Refresh', onPressed: refresh),
        ),
      );
  }
}
