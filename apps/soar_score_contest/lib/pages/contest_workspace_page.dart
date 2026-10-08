import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../router.dart';
import '../widgets/api_error_text.dart';
import '../widgets/contest_list.dart';
import '../widgets/contest_status_chip.dart';
import '../widgets/detail_section_card.dart';
import '../widgets/message_view.dart';
import '../widgets/workspace_nav_summary.dart';

/// The contest workspace for one contest (`plan/ui/contest-administration/
/// contest-workspace.md`): the contest's identity, its independent status
/// values and a summary of the pages that administer it.
class ContestWorkspacePage extends StatefulWidget {
  const ContestWorkspacePage({super.key, required this.contestId});

  /// The selected contest's id, taken from the route.
  final String contestId;

  @override
  State<ContestWorkspacePage> createState() => _ContestWorkspacePageState();
}

class _ContestWorkspacePageState extends State<ContestWorkspacePage> {
  Future<Contest>? _contest;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contest ??= _load();
  }

  @override
  void didUpdateWidget(ContestWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contestId != widget.contestId) {
      _contest = _load();
    }
  }

  Future<Contest> _load() {
    final client = apiClientOf(context);
    if (client == null) {
      return Future.error(StateError('No API client is available.'));
    }
    try {
      return client.contest(Id.parse(widget.contestId));
    } on ArgumentError {
      return Future.error(StateError('"${widget.contestId}" is not an id.'));
    }
  }

  void _retry() {
    final contest = _load();
    setState(() {
      _contest = contest;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Contest>(
    future: _contest,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return MessageView(
          text: 'The contest could not be loaded.',
          detail: apiErrorText(snapshot.error!),
          onRetry: _retry,
        );
      }
      final contest = snapshot.data;
      if (contest == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return _Workspace(contest: contest);
    },
  );
}

class _Workspace extends StatelessWidget {
  const _Workspace({required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = [
      contest.city,
      contest.state,
      contest.country,
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      children: [
        Text(contest.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ContestStatusChip(state: contest.lifecycleState),
            Chip(
              key: const ValueKey('workspace-scoring-access'),
              avatar: const Icon(Icons.sports_score, size: 18),
              label: Text(
                contest.scoringAccess == ScoringAccess.open
                    ? 'Scoring open'
                    : 'Scoring closed',
              ),
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              key: const ValueKey('workspace-admin-lock'),
              avatar: Icon(
                contest.adminLock == AdminLock.locked
                    ? Icons.lock
                    : Icons.lock_open,
                size: 18,
              ),
              label: Text(
                contest.adminLock == AdminLock.locked ? 'Locked' : 'Unlocked',
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 24),
        DetailSectionCard(
          title: 'Contest',
          items: [
            DetailItem('Dates', ContestList.contestDates(contest)),
            DetailItem('Timezone', contest.timezone),
            DetailItem('Host', contest.host),
            DetailItem('Location', location),
          ],
        ),
        const SizedBox(height: 24),
        Text('Administer', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        WorkspaceNavSummary(
          locations: {
            'Configuration': contestConfigurationPath(contest.id.value),
          },
          onOpen: context.go,
        ),
      ],
    );
  }
}
