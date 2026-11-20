import 'package:material_ui/material_ui.dart';

import '../public_site.dart';

/// A page that could not load: icon and words, and a way to try again.
class LoadErrorView extends StatelessWidget {
  const LoadErrorView({
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Retry',
    this.actionIcon = Icons.refresh,
    this.supportUri,
    this.supportLabel = 'Get support',
    this.opener = openInBrowser,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  /// What the button says and shows. Retry unless the page cannot be retried.
  final String actionLabel;
  final IconData actionIcon;

  /// When set, a secondary action opens this page (the public support form)
  /// through [opener]; [supportLabel] names it.
  final Uri? supportUri;
  final String supportLabel;
  final UrlOpener opener;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: onRetry,
              icon: Icon(actionIcon),
              label: Text(actionLabel),
            ),
            if (supportUri case final uri?) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                key: const ValueKey('load-error-support'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: () =>
                    openLinkOrExplain(context, uri, opener: opener),
                icon: const Icon(Icons.help_outline),
                label: Text(supportLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
