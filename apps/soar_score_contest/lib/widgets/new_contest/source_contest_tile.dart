import 'package:flutter/material.dart';

/// A contest that can be (or is) the copy source: an icon, its name and a
/// one-line description, with an optional trailing action.
class SourceContestTile extends StatelessWidget {
  const SourceContestTile({
    super.key,
    required this.icon,
    required this.name,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.outlined = false,
    this.footer,
  });

  final IconData icon;
  final String name;
  final String subtitle;
  final Widget? trailing;

  /// Makes the whole tile a button (the picker list).
  final VoidCallback? onTap;

  /// Draws a border (the chosen source).
  final bool outlined;

  /// Shown under the row, such as a progress bar.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: outlined ? 16 : 12,
        vertical: outlined ? 12 : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 220),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 22, color: scheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: theme.textTheme.bodyLarge),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 10), footer!],
        ],
      ),
    );
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: content,
        ),
      );
    }
    return Container(
      decoration: outlined
          ? BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: content,
    );
  }
}
