import 'package:flutter/material.dart';

import '../../services/configuration/section_id.dart';
import '../../services/configuration/section_notice.dart';
import 'config_chip.dart';

/// One section of the page: a card with its title, kind chips, purpose, the
/// notices about the contest's state and the section's [children].
class ConfigSectionCard extends StatelessWidget {
  const ConfigSectionCard({
    super.key,
    required this.id,
    required this.notices,
    required this.children,
    this.extraChips = const [],
  });

  final SectionId id;
  final List<SectionNotice> notices;
  final List<Widget> children;

  /// Chips after the kind chips, such as `2 house rules`.
  final List<Widget> extraChips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final warn = theme.brightness == Brightness.dark
        ? const Color(0xFFFFB870)
        : const Color(0xFF8A5100);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: id.title,
      child: Card(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Semantics(
                    header: true,
                    child: Text(id.title, style: theme.textTheme.titleLarge),
                  ),
                  for (final kind in id.kinds)
                    ConfigChip.neutral(
                      context,
                      icon: kind.icon,
                      text: kind.label,
                      tooltip: kind.description,
                      dense: false,
                    ),
                  ...extraChips,
                ],
              ),
              const SizedBox(height: 8),
              Text(
                id.purpose,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              for (final notice in notices) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        notice.icon,
                        size: 20,
                        color: notice.warning ? warn : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notice.text,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
