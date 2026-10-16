import 'package:flutter/material.dart';

import '../../services/scoring/scoring_controller.dart';
import '../../services/workspace/next_step/next_step_text.dart';
import 'completeness_menu.dart';

/// Round and group navigation on the left, group actions on the right.
class ScoringToolbar extends StatelessWidget {
  const ScoringToolbar({
    super.key,
    required this.controller,
    required this.onOpen,
    required this.onSaveAll,
  });

  final ScoringController controller;

  /// Asks the page to move to a round and group; the page handles unsaved
  /// edits before it calls the controller.
  final void Function(int round, int group) onOpen;
  final VoidCallback onSaveAll;

  @override
  Widget build(BuildContext context) {
    final data = controller.data!;
    final rounds = data.rounds;
    final round = controller.currentRound;
    final groups = round == null ? const <int>[] : data.groupNumbers(round);
    final roundIndex = rounds.indexWhere((r) => r.ordinal == controller.round);
    final groupIndex = groups.indexOf(controller.group);
    final dirty = controller.dirtyCount;
    final theme = Theme.of(context);

    void toRound(int index) {
      final target = rounds[index];
      onOpen(target.ordinal, 1);
    }

    void toGroup(int index) => onOpen(controller.round, groups[index]);

    Widget step(IconData icon, String tip, VoidCallback? onTap, String key) =>
        IconButton(
          key: ValueKey(key),
          icon: Icon(icon),
          tooltip: tip,
          onPressed: onTap,
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        );

    final roundNav = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        step(
          Icons.first_page,
          'First round',
          roundIndex > 0 ? () => toRound(0) : null,
          'round-first',
        ),
        step(
          Icons.chevron_left,
          'Previous round',
          roundIndex > 0 ? () => toRound(roundIndex - 1) : null,
          'round-previous',
        ),
        KeyedSubtree(
          key: const ValueKey('round-picker'),
          child: CompletenessMenu(
            title: 'Round ${controller.round} of ${rounds.length}',
            selected: controller.round,
            choices: [
              for (final r in rounds)
                PickerChoice(
                  value: r.ordinal,
                  label: 'Round ${r.ordinal}',
                  completeness: data.roundCompleteness(r),
                ),
            ],
            onSelected: (ordinal) => onOpen(ordinal, 1),
          ),
        ),
        step(
          Icons.chevron_right,
          'Next round',
          roundIndex >= 0 && roundIndex < rounds.length - 1
              ? () => toRound(roundIndex + 1)
              : null,
          'round-next',
        ),
        step(
          Icons.last_page,
          'Last round',
          roundIndex >= 0 && roundIndex < rounds.length - 1
              ? () => toRound(rounds.length - 1)
              : null,
          'round-last',
        ),
      ],
    );

    final pilots = round == null
        ? 0
        : data.rowsOf(round, controller.group).length;
    final groupNav = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        step(
          Icons.first_page,
          'First group',
          groupIndex > 0 ? () => toGroup(0) : null,
          'group-first',
        ),
        step(
          Icons.chevron_left,
          'Previous group',
          groupIndex > 0 ? () => toGroup(groupIndex - 1) : null,
          'group-previous',
        ),
        KeyedSubtree(
          key: const ValueKey('group-picker'),
          child: CompletenessMenu(
            title:
                'Group ${NextStepText.group(controller.group)} of ${groups.length}'
                ' · $pilots pilots',
            selected: controller.group,
            choices: [
              if (round != null)
                for (final g in groups)
                  PickerChoice(
                    value: g,
                    label: 'Group ${NextStepText.group(g)}',
                    completeness: data.groupCompleteness(round, g),
                  ),
            ],
            onSelected: (g) => onOpen(controller.round, g),
          ),
        ),
        step(
          Icons.chevron_right,
          'Next group',
          groupIndex >= 0 && groupIndex < groups.length - 1
              ? () => toGroup(groupIndex + 1)
              : null,
          'group-next',
        ),
        step(
          Icons.last_page,
          'Last group',
          groupIndex >= 0 && groupIndex < groups.length - 1
              ? () => toGroup(groups.length - 1)
              : null,
          'group-last',
        ),
      ],
    );

    final blocked = controller.block != null;
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('score-check'),
          onPressed: controller.rows.isEmpty ? null : controller.runCheck,
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Score check'),
        ),
        Tooltip(
          message: 'Locking is not available in this build yet.',
          child: OutlinedButton.icon(
            key: const ValueKey('score-lock'),
            onPressed: null,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Lock…'),
          ),
        ),
        FilledButton.icon(
          key: const ValueKey('score-save-all'),
          onPressed: dirty > 0 && !blocked ? onSaveAll : null,
          icon: const Icon(Icons.save),
          label: Text(dirty > 0 ? 'Save $dirty rows' : 'Nothing to save'),
        ),
      ],
    );

    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [roundNav, groupNav],
            ),
            actions,
          ],
        ),
      ),
    );
  }
}
