import 'dart:async';

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
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(ResultsControlCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contest.resultsHiddenAt != widget.contest.resultsHiddenAt) {
      _arm();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  /// While results are hidden, wakes the card each minute (and at the end of
  /// the 24 hours) so the countdown stays right and the card flips to Visible
  /// by itself.
  void _arm() {
    _tick?.cancel();
    _tick = null;
    final hiding = ResultsHiding.of(widget.contest, widget.clock());
    if (hiding is! ResultsHidden) {
      return;
    }
    final left = hiding.remainingAt(widget.clock());
    const minute = Duration(minutes: 1);
    final wait = left < minute ? left : minute;
    _tick = Timer(
      wait < const Duration(seconds: 1) ? const Duration(seconds: 1) : wait,
      () {
        if (mounted) {
          setState(() {});
          _arm();
        }
      },
    );
  }

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
    // run() refreshes the page before it returns, so the button is busy until
    // the new state is on screen, and a failure always frees it.
    try {
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
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  // Rounds up, so the countdown never understates what is left.
  String _remaining(AppLocalizations l10n, Duration left) {
    final minutes = left.inSeconds <= 0 ? 1 : (left.inSeconds + 59) ~/ 60;
    final time = minutes >= 60
        ? l10n.resultsCardRemainingHours((minutes + 59) ~/ 60)
        : l10n.resultsCardRemainingMinutes(minutes);
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
    final busy = _running;

    // Showing is always allowed; hiding only while Running.
    final String? reason = offline
        ? l10n.resultsCardNeedsConnection
        : hiding is ResultsVisible && !running
        ? l10n.resultsCardNotRunning
        : null;

    final (current, detail) = switch (hiding) {
      ResultsVisible() => (
        l10n.resultsCardVisible,
        l10n.resultsCardScopeVisible,
      ),
      final ResultsHidden h => (
        l10n.resultsCardHidden(
          h.throughRound,
          ContestTime.format(h.endsAt, zone),
        ),
        '${l10n.resultsCardScopeHidden} '
            '${_remaining(l10n, h.remainingAt(widget.clock()))}',
      ),
    };
    final hide = hiding is ResultsVisible;
    return ControlCardBody(
      control: WorkspaceControl.results,
      current: current,
      scope: detail,
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
