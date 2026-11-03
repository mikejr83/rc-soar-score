import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/scoring/scoring_controller.dart';
import '../../services/workspace/next_step/next_step_text.dart';
import 'completeness_menu.dart';

/// Round and group navigation on the left; on the right the group menu,
/// Score check and one primary action that follows the state of the group.
/// When entry is closed, the reason sits in a strip under the buttons.
class ScoringToolbar extends StatelessWidget {
  const ScoringToolbar({
    super.key,
    required this.controller,
    required this.onOpen,
    required this.onSaveAll,
    required this.onGroupHistory,
  });

  final ScoringController controller;

  /// Asks the page to move to a round and group; the page handles unsaved
  /// edits before it calls the controller.
  final void Function(int round, int group) onOpen;
  final VoidCallback onSaveAll;

  /// Opens the history of every row in the group.
  final VoidCallback onGroupHistory;

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
    final scheme = theme.colorScheme;
    final block = controller.block;
    final rows = controller.rows;

    Widget step(IconData icon, String tip, VoidCallback? onTap, String key) =>
        IconButton(
          key: ValueKey(key),
          icon: Icon(icon),
          tooltip: tip,
          onPressed: onTap,
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        );

    void toRound(int index) => onOpen(rounds[index].ordinal, 1);
    void toGroup(int index) => onOpen(controller.round, groups[index]);

    final roundNav = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
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
            completeness: round == null
                ? data.roundCompleteness(rounds.first)
                : data.roundCompleteness(round),
            selected: controller.round,
            choices: [
              for (final r in rounds)
                PickerChoice(
                  value: r.ordinal,
                  label: 'Round ${r.ordinal}',
                  sub: '${r.groupCount} groups',
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

    final groupNav = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
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
                'Group ${NextStepText.group(controller.group)} of '
                '${groups.length}',
            trailing: '${rows.length} pilots',
            completeness: round == null
                ? data.roundCompleteness(rounds.first)
                : data.groupCompleteness(round, controller.group),
            selected: controller.group,
            choices: [
              if (round != null)
                for (final g in groups)
                  PickerChoice(
                    value: g,
                    label: 'Group ${NextStepText.group(g)}',
                    sub: '${data.rowsOf(round, g).length} pilots',
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

    // One primary action per state: Save N rows, else Lock… (not built), and
    // a disabled Save with the reason when entry is closed.
    final String primaryLabel;
    final IconData primaryIcon;
    final VoidCallback? primaryTap;
    final savingCount = controller.savingCount;
    final saving = savingCount > 0;
    if (saving) {
      primaryLabel = AppLocalizations.of(context).scoreSavingRows(savingCount);
      primaryIcon = Icons.save;
      primaryTap = null;
    } else if (block != null) {
      primaryLabel = 'Save';
      primaryIcon = Icons.save;
      primaryTap = null;
    } else if (dirty > 0) {
      primaryLabel = 'Save $dirty ${dirty == 1 ? 'row' : 'rows'}';
      primaryIcon = Icons.save;
      primaryTap = onSaveAll;
    } else {
      primaryLabel = 'Lock…';
      primaryIcon = Icons.lock_outline;
      primaryTap = null;
    }
    final lockHint = block == null && dirty == 0;

    Widget pill({
      required Key key,
      required IconData icon,
      required String label,
      required VoidCallback? onTap,
      bool filled = false,
      bool busy = false,
    }) {
      final leading = busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 20);
      final style = ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      );
      return filled
          ? FilledButton.icon(
              key: key,
              onPressed: onTap,
              icon: leading,
              label: Text(label),
              style: style,
            )
          : OutlinedButton.icon(
              key: key,
              onPressed: onTap,
              icon: leading,
              label: Text(label),
              style: style,
            );
    }

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PopupMenuButton<String>(
          key: const ValueKey('group-more'),
          tooltip: 'More group actions',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'focus-order') controller.toggleFocusOrder();
            if (value == 'group-history') onGroupHistory();
          },
          itemBuilder: (context) => [
            CheckedPopupMenuItem<String>(
              key: const ValueKey('show-focus-order'),
              value: 'focus-order',
              checked: controller.showFocusOrder,
              child: const Text('Show keyboard order'),
            ),
            const PopupMenuItem<String>(
              key: ValueKey('menu-group-history'),
              value: 'group-history',
              child: Text('Group history'),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              enabled: false,
              child: Text('Re-flight group · Later release'),
            ),
            const PopupMenuItem<String>(
              enabled: false,
              child: Text('Re-flight round · Later release'),
            ),
          ],
        ),
        pill(
          key: const ValueKey('score-check'),
          icon: Icons.fact_check_outlined,
          label: 'Score check',
          onTap: rows.isEmpty ? null : controller.runCheck,
        ),
        Tooltip(
          message: lockHint
              ? 'Locking is not available in this build yet.'
              : '',
          child: pill(
            key: const ValueKey('score-save-all'),
            icon: primaryIcon,
            label: primaryLabel,
            onTap: primaryTap,
            filled: true,
            busy: saving,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final nav = Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [roundNav, groupNav],
              );
              // Navigation on the left, actions on the right.
              if (box.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    nav,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: nav),
                  const SizedBox(width: 16),
                  actions,
                ],
              );
            },
          ),
          if (saving)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                key: const ValueKey('score-saving-progress'),
                semanticsLabel: AppLocalizations.of(context)
                    .scoreSavingRows(savingCount),
              ),
            ),
          if (block != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                key: const ValueKey('score-reason'),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        block.message,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
