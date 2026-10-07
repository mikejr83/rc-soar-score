import 'package:flutter/material.dart';

import '../../services/new_contest/wizard_discipline.dart';
import 'discipline_card_slot.dart';

/// Step 2: pick exactly one discipline. The cards wrap to as many columns
/// as fit (300 px minimum).
class DisciplineStep extends StatelessWidget {
  const DisciplineStep({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final WizardDiscipline? selected;
  final ValueChanged<WizardDiscipline> onSelect;

  static const double _minCardWidth = 300;
  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: 'Discipline',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  ((constraints.maxWidth + _gap) / (_minCardWidth + _gap))
                      .floor()
                      .clamp(1, WizardDiscipline.values.length);
              final width =
                  (constraints.maxWidth - _gap * (columns - 1)) / columns;
              return Wrap(
                spacing: _gap,
                runSpacing: _gap,
                children: [
                  for (final discipline in WizardDiscipline.values)
                    SizedBox(
                      width: width,
                      child: DisciplineCardSlot(
                        discipline: discipline,
                        selected: discipline == selected,
                        onSelect: () => onSelect(discipline),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.tune,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'These are starting defaults. You can override task times, '
                'landing bonuses and rules after the contest is created, on '
                'the contest configuration page.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
