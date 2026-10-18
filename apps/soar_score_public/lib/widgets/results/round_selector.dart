import 'package:flutter/material.dart';

/// First, previous, dropdown, next, last over [rounds]. Presentational: the
/// owner changes the route in [onChanged]. Shared by every contest view.
class RoundSelector extends StatelessWidget {
  const RoundSelector({
    super.key,
    required this.rounds,
    required this.selected,
    required this.onChanged,
  });

  static const Key firstKey = Key('round_selector_first');
  static const Key previousKey = Key('round_selector_previous');
  static const Key dropdownKey = Key('round_selector_dropdown');
  static const Key nextKey = Key('round_selector_next');
  static const Key lastKey = Key('round_selector_last');

  /// Ascending round ordinals that can be selected.
  final List<int> rounds;
  final int? selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final index = selected == null ? -1 : rounds.indexOf(selected!);
    final hasPrevious = index > 0;
    final hasNext = index >= 0 && index < rounds.length - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: firstKey,
          tooltip: 'First round',
          icon: const Icon(Icons.first_page),
          onPressed: hasPrevious ? () => onChanged(rounds.first) : null,
        ),
        IconButton(
          key: previousKey,
          tooltip: 'Previous round',
          icon: const Icon(Icons.chevron_left),
          onPressed: hasPrevious ? () => onChanged(rounds[index - 1]) : null,
        ),
        DropdownButton<int>(
          key: dropdownKey,
          value: index >= 0 ? selected : null,
          hint: const Text('Round'),
          items: [
            for (final round in rounds)
              DropdownMenuItem(value: round, child: Text('Round $round')),
          ],
          onChanged: rounds.isEmpty ? null : (round) => onChanged(round!),
        ),
        IconButton(
          key: nextKey,
          tooltip: 'Next round',
          icon: const Icon(Icons.chevron_right),
          onPressed: hasNext ? () => onChanged(rounds[index + 1]) : null,
        ),
        IconButton(
          key: lastKey,
          tooltip: 'Last round',
          icon: const Icon(Icons.last_page),
          onPressed: hasNext ? () => onChanged(rounds.last) : null,
        ),
      ],
    );
  }
}
