import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Unknown or delisted contest (plan/ui/public-site/contest-not-found.md).
/// Shown in place; the route stays as the user entered it.
class ContestNotFoundPage extends StatelessWidget {
  const ContestNotFoundPage({super.key});

  static const String title = 'Contest not found';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.headlineSmall),
              const SizedBox(height: 12),
              const Text(
                'The contest or its results could not be found. One of the '
                'following may have happened:',
              ),
              const SizedBox(height: 8),
              const Text('- The address may have been entered incorrectly.'),
              const Text('- The contest may not have been published yet.'),
              const Text(
                '- The contest may have been removed at the direction of '
                'the contest director.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/results/contests'),
                child: const Text('Search contests'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
