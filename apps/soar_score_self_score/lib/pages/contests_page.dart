import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/sample_data.dart';
import '../router.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/contest_card.dart';
import '../widgets/is_this_you_card.dart';
import '../widgets/self_score_app_bar.dart';

/// The signed-in person's contests, with the "Is this you?" match prompt.
class ContestsPage extends StatelessWidget {
  const ContestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const SelfScoreAppBar(
        title: 'Contests',
        contextLine: SampleData.contestName,
        actions: [ConnectionIndicator()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const IsThisYouCard(
              message:
                  'Your email matches ${SampleData.pilotName}, pilot 12, in '
                  '${SampleData.contestName}.',
            ),
            const SizedBox(height: 16),
            Text('Your contests', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            ContestCard(
              name: SampleData.contestName,
              dates: 'Sat 10 Oct 2026 to Sun 11 Oct 2026',
              next: 'Round 4, Group B, lane 2',
              onTap: () => context.go(contestPath(SampleData.contestId)),
            ),
            const SizedBox(height: 16),
            Text(
              'Open the link your contest director sent you to add a contest '
              'here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
