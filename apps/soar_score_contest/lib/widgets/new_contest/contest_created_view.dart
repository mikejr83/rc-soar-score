import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'wizard_banner.dart';

/// Shown once the contest exists: it is in `Configuring`, unpublished and
/// private, the matrix isn't drawn, and the discipline overrides and the
/// remaining configuration can be reviewed next.
///
/// The contest configuration page isn't built yet, so this view stands in
/// for it and links to the contest.
class ContestCreatedView extends StatelessWidget {
  const ContestCreatedView({
    super.key,
    required this.contest,
    required this.disciplineName,
    required this.onOpen,
    required this.onDone,
  });

  final Contest contest;
  final String disciplineName;
  final VoidCallback onOpen;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget chip(IconData icon, String label) => Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );

    Widget card(IconData icon, String title, String value) => Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      key: const ValueKey('contest-created'),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(
                  contest.name,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              chip(Icons.tune, 'Configuring'),
              chip(Icons.lock, 'Private · Unpublished'),
            ],
          ),
          const SizedBox(height: 20),
          const WizardBanner(
            tone: WizardBannerTone.success,
            icon: Icons.check_circle,
            title: 'Contest created',
            body:
                'It’s in the Configuring state. The flight matrix hasn’t been '
                'drawn. Review the discipline overrides and the remaining '
                'configuration next.',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = ((constraints.maxWidth + 16) / 256).floor().clamp(
                1,
                3,
              );
              final width =
                  (constraints.maxWidth - 16 * (columns - 1)) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final (icon, title, value) in [
                    (
                      Icons.rule,
                      'Discipline overrides',
                      '$disciplineName defaults · not reviewed',
                    ),
                    (Icons.grid_view, 'Flight matrix', 'Not drawn'),
                    (Icons.public, 'Publication', 'Private and unpublished'),
                  ])
                    SizedBox(width: width, child: card(icon, title, value)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                key: const ValueKey('open-created-contest'),
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Open contest'),
              ),
              OutlinedButton(
                key: const ValueKey('back-to-contests'),
                onPressed: onDone,
                child: const Text('Back to Contests'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
