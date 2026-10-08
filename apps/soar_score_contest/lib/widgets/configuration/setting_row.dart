import 'package:flutter/material.dart';

/// The two-column layout of one setting: the label, its explanation and tags
/// on the leading side, the control and its notes on the trailing side. Below
/// about 560 px of width, or under large text, the columns stack.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.label,
    required this.help,
    required this.control,
    this.tags = const [],
    this.notes = const [],
    this.labelId,
    this.required = false,
    this.dimmed = false,
    this.heading,
    this.headingHelp,
  });

  final String label;
  final String help;
  final List<Widget> tags;
  final Widget control;
  final List<Widget> notes;
  final Key? labelId;
  final bool required;

  /// The setting is fixed, so its label is muted.
  final bool dimmed;

  /// A subheading shown above the row.
  final String? heading;
  final String? headingHelp;

  static const _stackBelow = 560.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stack = MediaQuery.textScalerOf(context).scale(16) > 24;
    final labelColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              label,
              key: labelId,
              style: theme.textTheme.titleMedium?.copyWith(
                color: dimmed ? scheme.onSurfaceVariant : scheme.onSurface,
              ),
            ),
            if (required)
              Text(
                'Required',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          help,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: tags),
        ],
      ],
    );
    final controlColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        control,
        for (final note in notes) ...[const SizedBox(height: 8), note],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading != null)
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                  ),
                ),
                if (headingHelp != null)
                  Text(
                    headingHelp!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        Divider(height: 1, color: scheme.outlineVariant),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (stack || constraints.maxWidth < _stackBelow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    labelColumn,
                    const SizedBox(height: 12),
                    controlColumn,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: labelColumn),
                  const SizedBox(width: 32),
                  Expanded(flex: 6, child: controlColumn),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
