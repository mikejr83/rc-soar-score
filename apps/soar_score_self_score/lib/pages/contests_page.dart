import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/self_score_scope.dart';
import '../models/contests_view.dart';
import '../router.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/contest_card.dart';
import '../widgets/is_this_you_card.dart';
import '../widgets/loadable_scaffold.dart';
import '../widgets/self_score_app_bar.dart';

/// The signed-in person's contests, with the "Is this you?" match prompt.
class ContestsPage extends StatelessWidget {
  const ContestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.repository;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return LoadableScaffold<ContestsView>(
      load: repository.contests,
      reloadKey: repository,
      appBar: (context, data) => const SelfScoreAppBar(
        title: 'Contests',
        actions: [ConnectionIndicator()],
      ),
      builder: (context, data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (data.matchPrompt != null) ...[
            IsThisYouCard(message: data.matchPrompt!),
            const SizedBox(height: 16),
          ],
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
