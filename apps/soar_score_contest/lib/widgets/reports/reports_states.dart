import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

/// The loading state: a progress bar over the shapes of the page.
class ReportsLoading extends StatelessWidget {
  const ReportsLoading({super.key, required this.twoColumns});

  final bool twoColumns;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
      label: l10n.reportsLoadingLabel,
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
          Text(l10n.reportsLoadingText),
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
    final l10n = AppLocalizations.of(context);
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
                  l10n.reportsUnavailableTitle,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                Text(
                  l10n.reportsUnavailableBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                FilledButton.icon(
                  key: const ValueKey('reports-retry'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: Text(l10n.reportsUnavailableRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
