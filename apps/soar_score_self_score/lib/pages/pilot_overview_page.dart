import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/score_changes.dart';
import '../data/self_score_repository.dart';
import '../data/self_score_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/pilot_overview.dart';
import '../router.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/end_session_button.dart';
import '../widgets/loadable_scaffold.dart';
import '../widgets/pilot_round_card.dart';
import '../widgets/self_score_app_bar.dart';
import '../widgets/status_chip.dart';

/// One round card per round for a pilot, with the pilot's actions. A helper
/// reaches it from the team overview and sees what the pilot would see.
class PilotOverviewPage extends StatelessWidget {
  const PilotOverviewPage({
    required this.contestId,
    required this.pilotId,
    super.key,
  });

  final String contestId;
  final String pilotId;

  Future<void> _confirmRetire(BuildContext context, String name) async {
    final retire = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Retire $name?'),
        content: const Text(
          'Future and unscored rounds count as zero, and score entry will '
          'be locked. The contest director can reinstate the pilot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retire pilot'),
          ),
        ],
      ),
    );
    if (retire == true && context.mounted) {
      _notYet(context, 'Retiring a pilot is not connected yet (#146).');
    }
  }

  /// Copies the pilot's own invitation link. The server rebuilds it for the
  /// session, so the link is never kept in the browser.
  Future<void> _copyInvitationLink(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repository = context.repository;
    String message;
    try {
      final link = await repository.invitationLink();
      await Clipboard.setData(ClipboardData(text: link));
      message = l10n.invitationLinkCopied;
    } on SelfScoreLoadException {
      message = l10n.invitationLinkCopyFailed;
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _notYet(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final repository = context.repository;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final l10n = AppLocalizations.of(context);
    // A score accepted while this page sits under the entry form changes what
    // it shows, so the count reloads it.
    return ValueListenableBuilder<int>(
      valueListenable: scoreChanges,
      builder: (context, changes, _) => LoadableScaffold<PilotOverview>(
        load: () => repository.pilotOverview(contestId, pilotId),
        reloadKey: (repository, contestId, pilotId, changes),
        appBar: (context, data) => SelfScoreAppBar(
          title: data == null
              ? 'Pilot overview'
              : data.pilotNumber == null
              ? data.pilotName
              : '${data.pilotName}, pilot ${data.pilotNumber}',
          contextLine: data == null
              ? null
              : [data.contestName, ?data.teamName].join(' · '),
          // Only a pilot on a team has a team overview to go back to.
          onBack: data?.teamName == null
              ? null
              : () => context.go(teamPath(contestId)),
          backLabel: l10n.backToPilots,
          actions: [
            const ConnectionIndicator(),
            IconButton(
              tooltip: l10n.copyInvitationLink,
              icon: const Icon(Icons.link),
              onPressed: () => _copyInvitationLink(context),
            ),
            const EndSessionButton(),
          ],
          showAccount: false,
        ),
        builder: (context, data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AccessChip(access: data.access),
                Text(
                  '${data.rounds.length} rounds',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Find your group and lane for each round. Score a round in the '
              'order it is listed.',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 12),
            for (final round in data.rounds) ...[
              PilotRoundCard(
                round: round,
                nextRound: data.nextRound,
                onEnter: () => context.push(
                  scoreEntryPath(contestId, pilotId, '${round.number}'),
                ),
                // A submitted round opens its score entry page read-only; the
                // form links on to the group results.
                onView: () => context.push(
                  scoreEntryPath(contestId, pilotId, '${round.number}'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const Divider(height: 32),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () => context.push(resultsPath(contestId)),
              icon: const Icon(Icons.leaderboard_outlined, size: 20),
              label: Text(l10n.currentResults),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
              onPressed: () => _confirmRetire(context, data.pilotName),
              icon: const Icon(Icons.person_off_outlined, size: 20),
              label: Text(l10n.retirePilot),
            ),
          ],
        ),
      ),
    );
  }
}

/// The contest-level scoring state, from the server's access answer.
class _AccessChip extends StatelessWidget {
  const _AccessChip({required this.access});

  final ScoringAccess access;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (access) {
      ScoringAccess.open => StatusChip(
        label: l10n.scoringOpen,
        icon: Icons.lock_open_outlined,
      ),
      ScoringAccess.notStarted => StatusChip(
        label: l10n.scoringNotStarted,
        icon: Icons.schedule,
        style: StatusChipStyle.quiet,
      ),
      ScoringAccess.closed => StatusChip(
        label: l10n.scoringClosed,
        icon: Icons.lock_outline,
        style: StatusChipStyle.quiet,
      ),
      ScoringAccess.completed => StatusChip(
        label: l10n.scoringCompleted,
        icon: Icons.flag_outlined,
        style: StatusChipStyle.quiet,
      ),
    };
  }
}
