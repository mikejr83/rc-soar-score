import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';

/// The card while the facts load, and when they could not be loaded at all.
class NextStepPlaceholderCard extends StatelessWidget {
  const NextStepPlaceholderCard({super.key, this.onRetry});

  /// Set when loading failed: the card says so and offers Retry. `null`
  /// shows the loading state.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card.filled(
      key: const ValueKey('next-step-placeholder'),
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: onRetry == null
            ? Row(
                children: [
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.workspaceNextStepLoading,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              )
            : Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  Text(
                    l10n.workspaceNextStepFailed,
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    key: const ValueKey('next-step-retry'),
                    onPressed: onRetry,
                    child: Text(l10n.workspaceRetry),
                  ),
                ],
              ),
      ),
    );
  }
}
