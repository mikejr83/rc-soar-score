import 'package:flutter/material.dart';

/// The loading state: a progress bar over the shapes of the page.
class ReportsLoading extends StatelessWidget {
  const ReportsLoading({super.key, required this.twoColumns});

  final bool twoColumns;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget block(double height, [double opacity = 1]) => Opacity(
      opacity: opacity,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    final cards = [
      for (final opacity in [1.0, .8, .6, .45]) block(176, opacity),
    ];
    return Semantics(
      label: 'Loading reports',
      container: true,
      child: Column(
        key: const ValueKey('reports-loading'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          const LinearProgressIndicator(),
          block(88),
          if (twoColumns)
            for (var i = 0; i < cards.length; i += 2)
              Row(
                spacing: 16,
                children: [
                  Expanded(child: cards[i]),
                  Expanded(child: cards[i + 1]),
                ],
              )
          else
            ...cards,
          const Text('Loading reports…'),
        ],
      ),
    );
  }
}

/// The data could not be read: nothing has changed, and a retry is offered.
class ReportsUnavailable extends StatelessWidget {
  const ReportsUnavailable({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Column(
              key: const ValueKey('reports-unavailable'),
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: scheme.errorContainer,
                  child: Icon(
                    Icons.error,
                    size: 32,
                    color: scheme.onErrorContainer,
                  ),
                ),
                Text(
                  'Can’t read this contest’s data',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'The reports list needs the contest’s matrix and scores, '
                  'and they couldn’t be loaded from this device or the '
                  'server. Nothing has changed.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                FilledButton.icon(
                  key: const ValueKey('reports-retry'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
