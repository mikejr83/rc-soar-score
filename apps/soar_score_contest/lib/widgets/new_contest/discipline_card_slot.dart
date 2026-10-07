import 'package:flutter/material.dart';

import '../../services/new_contest/wizard_discipline.dart';
import 'discipline_card.dart';

/// A [DisciplineCard] that is as tall as the tallest discipline card at the
/// same width, so the cards line up in every row.
///
/// Invisible copies of every card are stacked underneath; the stack sizes
/// itself to the tallest, and the real card fills it.
class DisciplineCardSlot extends StatelessWidget {
  const DisciplineCardSlot({
    super.key,
    required this.discipline,
    required this.selected,
    required this.onSelect,
  });

  final WizardDiscipline discipline;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (final other in WizardDiscipline.values)
        ExcludeSemantics(
          child: Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: DisciplineCard(
              discipline: other,
              selected: false,
              onSelect: () {},
              sizingOnly: true,
            ),
          ),
        ),
      Positioned.fill(
        child: DisciplineCard(
          discipline: discipline,
          selected: selected,
          onSelect: onSelect,
        ),
      ),
    ],
  );
}
