import 'package:flutter/material.dart';

import '../../services/configuration/config_impact.dart';

/// One titled group of the contest configuration, with the revision it
/// belongs to and what editing it affects.
class ConfigGroupCard extends StatelessWidget {
  const ConfigGroupCard({
    super.key,
    required this.title,
    required this.children,
    this.impact,
    this.revisionLabel,
  });

  final String title;

  /// Shown as a chip; omitted for groups that are not stored in the
  /// configuration.
  final ConfigImpact? impact;

  /// For example `Configuration revision 3`.
  final String? revisionLabel;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (revisionLabel != null)
                  Text(
                    revisionLabel!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (impact != null)
                  Chip(
                    label: Text(impact!.label),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: impact == ConfigImpact.none
                          ? theme.colorScheme.outlineVariant
                          : theme.colorScheme.tertiary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
