import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../data/self_score_scope.dart';
import '../models/contests_view.dart';
import '../router.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/contest_card.dart';
import '../widgets/link_candidates_section.dart';
import '../widgets/loadable_scaffold.dart';
import '../widgets/self_score_app_bar.dart';

/// The signed-in person's contests, with the "Is this you?" match prompt.
class ContestsPage extends StatefulWidget {
  const ContestsPage({super.key});

  @override
  State<ContestsPage> createState() => _ContestsPageState();
}

class _ContestsPageState extends State<ContestsPage> {
  /// Counts confirmed "Is this you?" answers; the list loads again after one,
  /// because the link brings contests.
  int _linked = 0;

  @override
  Widget build(BuildContext context) {
    final repository = context.repository;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return LoadableScaffold<ContestsView>(
      load: repository.contests,
      reloadKey: (repository, _linked),
      appBar: (context, data) => const SelfScoreAppBar(
        title: 'Contests',
        actions: [ConnectionIndicator()],
      ),
      builder: (context, data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LinkCandidatesSection(onLinked: () => setState(() => _linked++)),
          Text('Your contests', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          if (data.contests.isEmpty)
            Text(
              'You are not in a contest yet. Open the link your contest '
              'director sent you.',
              style: theme.textTheme.bodyLarge?.copyWith(color: muted),
            )
          else
            for (final contest in data.contests) ...[
              ContestCard(
                name: contest.name,
                dates: contest.dates,
                next: contest.next,
                onTap: () => context.go(contestPath(contest.id)),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 8),
          Text(
            'Open the link your contest director sent you to add a contest '
            'here.',
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
