import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../services/workspace/controls/contest_transition.dart';
import '../../../services/workspace/next_step/completion_dismissals.dart';
import '../../../services/workspace/next_step/next_step.dart';
import '../../../services/workspace/next_step/next_step_action.dart';
import '../../../services/workspace/next_step/next_step_kind.dart';
import '../../../services/workspace/next_step/next_step_resolver.dart';
import '../../../services/workspace/next_step/next_step_target.dart';
import '../workspace_scope.dart';
import '../controls/contest_transition_runner.dart';
import 'next_step_card.dart';
import 'next_step_navigator.dart';
import 'next_step_placeholder_card.dart';

final _logger = Logger('NextStepSection');

/// What the snackbar says after dismissing a suggestion. The messages after
/// a transition are in `contest_transition.dart`.
const String suggestionDismissedMessage =
    'Suggestion dismissed. It returns if another 48 hours pass without '
    'scores.';

/// The next-step section of the workspace: resolves the step from the
/// workspace facts and connects its buttons.
class NextStepSection extends StatefulWidget {
  const NextStepSection({
    super.key,
    required this.contest,
    required this.dismissals,
    required this.clock,
  });

  final Contest contest;

  /// The dismissed completion suggestions; owned by the page so a reload
  /// does not bring a dismissed suggestion back.
  final CompletionDismissals dismissals;

  /// The current time, injectable for tests.
  final DateTime Function() clock;

  @override
  State<NextStepSection> createState() => _NextStepSectionState();
}

class _NextStepSectionState extends State<NextStepSection> {
  // True while an in-place action runs.
  bool _running = false;

  // The revision the last in-place action produced. The card stays busy until
  // the facts show it, so the old step cannot be tapped again meanwhile.
  int? _pendingRevision;

  NextStepKind? _lastKind;
  String? _lastTitle;

  @override
  Widget build(BuildContext context) {
    final scope = WorkspaceScope.of(context);
    final facts = scope.facts;
    if (facts == null) {
      return NextStepPlaceholderCard(
        onRetry: scope.factsFailed ? scope.reloadFacts : null,
      );
    }
    final pending = _pendingRevision;
    final busy =
        _running || (pending != null && facts.contest.revision < pending);
    final step = resolveNextStep(
      facts,
      now: widget.clock(),
      completionSuggestionDismissed: widget.dismissals.isDismissed(
        facts.contest.id.value,
        latestScoreAt: facts.latestScore?.setAt,
        now: widget.clock(),
      ),
    );
    _announceChange(scope, step);
    _logger.fine('Next step resolved: ${step.title} (${step.kind})');
    _logger.finer(
      () => 'facts.nextStepFactsUnavailable: ${facts.nextStepFactsUnavailable}',
    );
    return NextStepCard(
      step: step,
      busy: busy,
      factsUnavailable: facts.nextStepFactsUnavailable,
      onRetryFacts: scope.reloadFacts,
      onPressed: (action) =>
          _onPressed(scope, facts.latestScore?.setAt, action),
    );
  }

  // Says the new title when the step changes after the first one. A step
  // can keep its title and change kind (a locked step becomes its unlocked
  // self), which is still a change.
  void _announceChange(WorkspaceScope scope, NextStep step) {
    final previousKind = _lastKind;
    final previousTitle = _lastTitle;
    _lastKind = step.kind;
    _lastTitle = step.title;
    if (previousKind != null &&
        (previousKind != step.kind || previousTitle != step.title)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          scope.announce(step.title);
        }
      });
    }
  }

  void _onPressed(
    WorkspaceScope scope,
    DateTime? latestScoreAt,
    NextStepAction action,
  ) {
    if (_running) {
      return;
    }
    switch (action.target) {
      case NextStepTarget.dismissSuggestion:
        widget.dismissals.dismiss(
          widget.contest.id.value,
          latestScoreAt: latestScoreAt,
          now: widget.clock(),
        );
        setState(() {});
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(suggestionDismissedMessage)),
          );
      case NextStepTarget.openScoring:
        _run(scope, ContestTransition.openScoring);
      case NextStepTarget.unlock:
        _run(scope, ContestTransition.unlock);
      case NextStepTarget.completeDialog:
        _run(scope, ContestTransition.complete);
      default:
        NextStepNavigator.open(
          context,
          action,
          contestId: widget.contest.id.value,
        );
    }
  }

  Future<void> _run(WorkspaceScope scope, ContestTransition transition) async {
    if (!await confirmTransition(context, scope, transition) || !mounted) {
      return;
    }
    setState(() {
      _running = true;
    });
    final updated = await runTransition(
      context,
      scope,
      widget.contest,
      transition,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _running = false;
      _pendingRevision = updated?.revision;
    });
  }
}
