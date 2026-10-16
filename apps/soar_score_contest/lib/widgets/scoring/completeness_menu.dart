import 'package:flutter/material.dart';

import '../../services/scoring/scoring_completeness.dart';
import 'status_chips.dart';

/// One choice of a round or group picker, with how complete it is.
class PickerChoice {
  const PickerChoice({
    required this.value,
    required this.label,
    required this.completeness,
  });

  final int value;
  final String label;
  final Completeness completeness;
}

/// A button that opens a menu of [choices]. Each carries its completeness as
/// an icon and words, so the director sees where work remains.
class CompletenessMenu extends StatelessWidget {
  const CompletenessMenu({
    super.key,
    required this.title,
    required this.choices,
    required this.selected,
    required this.onSelected,
  });

  /// "Round 3 of 8".
  final String title;
  final List<PickerChoice> choices;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Choose',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final choice in choices)
          PopupMenuItem<int>(
            value: choice.value,
            key: ValueKey('picker-item-${choice.value}'),
            child: Row(
              children: [
                Icon(choice.value == selected ? Icons.check : null, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(choice.label)),
                const SizedBox(width: 12),
                Icon(completenessIcon(choice.completeness.state), size: 18),
                const SizedBox(width: 6),
                Text(
                  choice.completeness.total == 0
                      ? choice.completeness.state.label
                      : '${choice.completeness.state.label} · '
                            '${choice.completeness.counts}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
