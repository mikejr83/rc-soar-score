import 'package:flutter/material.dart';

/// A notice at the top of the page about the whole contest: administration
/// locked, contest completed, scoring started, no configuration saved yet.
class ConfigBanner extends StatelessWidget {
  const ConfigBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.info = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;

  /// Uses the primary container instead of the neutral one.
  final bool info;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = info
        ? scheme.primaryContainer
        : scheme.surfaceContainerHigh;
    final foreground = info ? scheme.onPrimaryContainer : scheme.onSurface;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Icon(icon, color: foreground),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200, maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
            if (actionLabel != null)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: foreground,
                  side: BorderSide(color: foreground),
                ),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
