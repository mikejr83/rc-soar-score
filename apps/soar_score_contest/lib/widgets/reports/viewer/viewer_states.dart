import 'package:flutter/material.dart';

import 'paper_style.dart';

/// The viewer's loading state: a grey page-shaped skeleton with a progress bar
/// on the sheet backdrop.
class ViewerLoading extends StatelessWidget {
  const ViewerLoading({
    super.key,
    required this.pageAspect,
    this.label = 'Loading contest data…',
  });

  /// Page width over height.
  final double pageAspect;

  /// What is being waited for.
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: PaperStyle.backdrop(theme.brightness),
      child: Semantics(
        label: label,
        container: true,
        child: Column(
          key: const ValueKey('viewer-loading'),
          children: [
            const LinearProgressIndicator(),
            // The page-shaped skeleton takes what room there is, so a short
            // window scales it down instead of overflowing.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: AspectRatio(
                            aspectRatio: pageAspect,
                            child: const ColoredBox(color: Color(0xFFEFEFEF)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(label),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A message in the middle of the sheet area: unavailable, or nothing to show.
class ViewerMessage extends StatelessWidget {
  const ViewerMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ColoredBox(
      color: PaperStyle.backdrop(theme.brightness),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Semantics(
              container: true,
              liveRegion: true,
              child: Column(
                key: const ValueKey('viewer-message'),
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: isError
                        ? scheme.errorContainer
                        : scheme.surfaceContainerHigh,
                    child: Icon(
                      icon,
                      size: 32,
                      color: isError
                          ? scheme.onErrorContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  FilledButton(
                    key: const ValueKey('viewer-message-action'),
                    onPressed: onAction,
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
