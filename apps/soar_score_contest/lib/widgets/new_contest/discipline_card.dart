import 'package:flutter/material.dart';

import '../../services/new_contest/wizard_discipline.dart';

/// One discipline's selection card: name, task type, default time, landing
/// bonus and rules. Unsupported disciplines show but can't be selected.
class DisciplineCard extends StatelessWidget {
  const DisciplineCard({
    super.key,
    required this.discipline,
    required this.selected,
    required this.onSelect,
    this.sizingOnly = false,
  });

  final WizardDiscipline discipline;
  final bool selected;
  final VoidCallback onSelect;

  /// Whether this copy only exists to be measured, so it carries no key and
  /// can't be selected. See `DisciplineCardSlot`.
  final bool sizingOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final supported = discipline.supported;
    final disabled = scheme.onSurface.withValues(alpha: 0.38);
    final foreground = supported ? scheme.onSurface : disabled;
    final secondary = supported ? scheme.onSurfaceVariant : disabled;
    final body = theme.textTheme.bodyMedium;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: supported,
      label: supported
          ? '${discipline.name}. ${discipline.task}'
          : '${discipline.name}, ${WizardDiscipline.unsupportedLabel}. '
                '${discipline.task}',
      excludeSemantics: true,
      child: Material(
        color: supported ? scheme.secondaryContainer : Colors.transparent,
        elevation: selected ? 1 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: sizingOnly ? null : ValueKey('discipline-${discipline.name}'),
          onTap: supported && !selected && !sizingOnly ? onSelect : null,
          mouseCursor: supported
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        discipline.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: foreground,
                        ),
                      ),
                    ),
                    if (selected)
                      _Badge(
                        icon: Icons.check,
                        label: 'Selected',
                        background: scheme.primaryContainer,
                        foreground: scheme.onPrimaryContainer,
                      )
                    else if (!supported)
                      _Badge(
                        icon: Icons.block,
                        label: WizardDiscipline.unsupportedLabel,
                        background: scheme.surfaceContainerHighest,
                        foreground: scheme.onSurfaceVariant,
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: !supported
                          ? disabled
                          : selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(discipline.task, style: body?.copyWith(color: secondary)),
                if (supported) ...[
                  const SizedBox(height: 12),
                  Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FlexColumnWidth(),
                    },
                    children: [
                      for (final (label, value) in [
                        ('Time', discipline.time!),
                        ('Landing', discipline.landing!),
                      ])
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 16,
                                bottom: 4,
                              ),
                              child: Text(
                                label,
                                style: body?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(value, style: body),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: scheme.outlineVariant),
                  const SizedBox(height: 10),
                  for (final rule in discipline.rules)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.rule,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(rule, style: body)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    padding: const EdgeInsetsDirectional.only(start: 6, end: 8),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: foreground),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: foreground, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}
