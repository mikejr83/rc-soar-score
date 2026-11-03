import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../api_client_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/workspace/controls/results_hiding.dart';
import '../../../services/workspace/workspace_control.dart';
import '../next_step/contest_action_runner.dart';
import '../workspace_scope.dart';
import 'control_card_body.dart';

/// The "Overall results" card: whether overall scores and placing are shown
/// or hidden, with the one button that flips it.
///
/// Hiding and showing take effect directly, with a snackbar and Undo (the
/// workspace brief). The server picks the round hiding runs through.
class ResultsControlCard extends StatefulWidget {
  const ResultsControlCard({
    super.key,
    required this.contest,
    required this.clock,
  });

  final Contest contest;

  /// The current time, injectable for tests.
  final DateTime Function() clock;

  @override
  State<ResultsControlCard> createState() => _ResultsControlCardState();
}

class _ResultsControlCardState extends State<ResultsControlCard> {
  bool _running = false;

  // The revision the change produced; the button stays busy until the page
  // shows it, so the old state cannot be changed twice.
  int? _pendingRevision;

  Future<void> _press(ResultsHiding hiding) async {
    final l10n = AppLocalizations.of(context);
    final scope = WorkspaceScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final client = apiClientOf(context);
    if (client == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.resultsCardNoApi)));
      return;
    }
    final hide = hiding is ResultsVisible;
    setState(() => _running = true);
    final updated =
        await ContestActionRunner(
          client: client,
          messenger: messenger,
          refresh: scope.refresh,
          onStale: scope.reportStale,
        ).run(
          widget.contest,
          hide ? ContestAction.hideResults : ContestAction.showResults,
          what: l10n.resultsCardWhat,
          done: hide
              ? l10n.resultsCardHiddenMessage
              : l10n.resultsCardShownMessage,
          undo: hide ? ContestAction.showResults : ContestAction.hideResults,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _running = false;
      _pendingRevision = updated?.revision;
    });
  }

  String _remaining(AppLocalizations l10n, Duration left) {
    final hours = left.inHours;
    final time = hours >= 1
        ? l10n.resultsCardRemainingHours(hours)
        : l10n.resultsCardRemainingMinutes(left.inMinutes.clamp(1, 59));
    return l10n.resultsCardRemaining(time);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contest = widget.contest;
    final hiding = ResultsHiding.of(contest, widget.clock());
    final zone = ContestTimeZones.isValid(contest.timezone)
        ? contest.timezone
        : ContestTimeZones.utc;
    final offline = WorkspaceScope.of(context).facts?.isOffline ?? false;
    final running = contest.lifecycleState == LifecycleState.running;
    final pending = _pendingRevision;
    final busy = _running || (pending != null && contest.revision < pending);

    // Showing is always allowed; hiding only while Running.
    final String? reason = offline
        ? l10n.resultsCardNeedsConnection
        : hiding is ResultsVisible && !running
        ? l10n.resultsCardNotRunning
        : null;

    final (current, scope) = switch (hiding) {
      ResultsVisible() => (
        l10n.resultsCardVisible,
        l10n.resultsCardScopeVisible,
      ),
      ResultsHidden(:final throughRound, :final endsAt, :final remaining) => (
        l10n.resultsCardHidden(throughRound, ContestTime.format(endsAt, zone)),
        '${l10n.resultsCardScopeHidden} ${_remaining(l10n, remaining)}',
      ),
    };
    final hide = hiding is ResultsVisible;
    return ControlCardBody(
      control: WorkspaceControl.results,
      current: current,
      scope: scope,
      disabledReason: reason,
      button: FilledButton.tonalIcon(
        key: ValueKey(hide ? 'control-hideResults' : 'control-showResults'),
        onPressed: reason == null && !busy ? () => _press(hiding) : null,
        icon: busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(hide ? Icons.visibility_off : Icons.visibility),
        label: Text(
          busy
              ? (hide ? l10n.resultsCardHideBusy : l10n.resultsCardShowBusy)
              : (hide ? l10n.resultsCardHide : l10n.resultsCardShow),
        ),
      ),
    );
  }
}
