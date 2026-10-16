import 'package:flutter/material.dart';

import '../../services/scoring/scoring_completeness.dart';
import 'status_chips.dart';

/// One choice of a round or group picker, with how complete it is.
class PickerChoice {
  const PickerChoice({
    required this.value,
    required this.label,
    required this.sub,
    required this.completeness,
  });

  final int value;
  final String label;

  /// The line under the label, such as "7 pilots".
  final String sub;
  final Completeness completeness;
}

/// A button that opens a menu of [choices]. Each carries its completeness as
/// an icon and words, so the director sees where work remains.
class CompletenessMenu extends StatelessWidget {
  const CompletenessMenu({
    super.key,
    required this.title,
    required this.completeness,
    required this.choices,
    required this.selected,
    required this.onSelected,
    this.trailing,
  });

  /// "Round 3 of 8".
  final String title;

  /// The state of the current choice, shown as the button's icon.
  final Completeness completeness;
  final List<PickerChoice> choices;
  final int selected;
  final ValueChanged<int> onSelected;

  /// Small text after the title, such as "7 pilots".
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PopupMenuButton<int>(
      tooltip: 'Go to…',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final choice in choices)
          PopupMenuItem<int>(
            value: choice.value,
            key: ValueKey('picker-item-${choice.value}'),
            height: 52,
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: choice.value == selected
                      ? const Icon(Icons.check, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(choice.label, style: theme.textTheme.labelLarge),
                      Text(choice.sub, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CompletenessChip(completeness: choice.completeness),
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.only(left: 12, right: 6),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              completenessIcon(completeness.state),
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  trailing!,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const Icon(Icons.arrow_drop_down, size: 22),
          ],
        ),
      ),
    );
  }
}

/// How complete a round or group is: an icon and words, filled for the
/// states that are done.
class CompletenessChip extends StatelessWidget {
  const CompletenessChip({super.key, required this.completeness});

  final Completeness completeness;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = completeness.state;
    final (Color? bg, Color fg) = switch (state) {
      CompletenessState.empty => (null, scheme.onSurfaceVariant),
      CompletenessState.partial => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      CompletenessState.entered => (
        scheme.surfaceContainerHigh,
        scheme.onSurface,
      ),
      CompletenessState.official => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      CompletenessState.locked => (
        scheme.inverseSurface,
        scheme.onInverseSurface,
      ),
    };
    return StatusChip(
      icon: completenessIcon(state),
      label: state.label,
      background: bg,
      foreground: fg,
      dense: true,
    );
  }
}
