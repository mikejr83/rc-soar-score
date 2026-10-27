import 'package:flutter/material.dart';

import '../../services/contest_participants/participants_controller.dart';
import '../../services/contest_participants/stored_participant.dart';

/// The Save control, docked above the status bar and always there: the
/// `Save changes` button, then the reason it is off (an icon, one sentence
/// and a fix link) the way the Matrix draw action shows it.
///
/// Edits wait here until Save; adding and removing people act at once from
/// the toolbar above the list. After a save that left rows unsaved, a summary
/// names them next to the button.
class ParticipantsSaveBar extends StatelessWidget {
  const ParticipantsSaveBar({
    super.key,
    required this.controller,
    required this.onShowRow,
  });

  final ParticipantsController controller;

  /// Moves focus to a row that needs attention.
  final ValueChanged<StoredParticipant> onShowRow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = controller;
    final busy = c.saving;
    final changed = c.changedIds.length;
    final stale = c.staleIds;
    final invalid = c.invalidChanged;

    final (IconData, String, String?, VoidCallback?)? reason;
    if (stale.isNotEmpty) {
      reason = (
        Icons.sync_problem,
        'Someone changed this participant. Refresh to continue.',
        'Refresh',
        () => c.refreshRow(stale.first),
      );
    } else if (invalid.isNotEmpty) {
      reason = (
        Icons.error,
        'Fix ${invalid.length} row${invalid.length == 1 ? '' : 's'} before '
            'saving.',
        'Show row',
        () => onShowRow(invalid.first),
      );
    } else if (changed == 0 && !busy) {
      reason = (Icons.check, 'No changes to save.', null, null);
    } else {
      reason = null;
    }
    final off = reason != null || busy;
    final failed = c.failedRows;

    Widget reasonBlock(
      IconData icon,
      String text,
      String? link,
      VoidCallback? fix,
    ) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: DecoratedBox(
          key: const ValueKey('save-reason'),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Text(text),
                ),
                if (link != null && fix != null)
                  TextButton(
                    key: const ValueKey('save-reason-link'),
                    onPressed: fix,
                    child: Text(link),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return Material(
      color: scheme.surface,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (failed.isNotEmpty && !busy) ...[
                Semantics(
                  container: true,
                  liveRegion: true,
                  child: Column(
                    key: const ValueKey('save-summary'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${c.savedCount} saved. ${failed.length} not saved. '
                        'Their typed values are kept.',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final row in failed)
                            TextButton(
                              onPressed: () => onShowRow(row),
                              child: Text(
                                '${row.name}: ${c.stateOf(row.rowId).message ?? ''}',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('save-participants'),
                    onPressed: off ? null : c.save,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(busy ? 'Saving…' : 'Save changes'),
                  ),
                  if (reason != null)
                    reasonBlock(reason.$1, reason.$2, reason.$3, reason.$4)
                  else
                    Text(
                      busy
                          ? 'Saving $changed participant'
                                '${changed == 1 ? '' : 's'}. Rows are locked '
                                'until it finishes.'
                          : 'Each participant saves on its own.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (changed > 0 && !busy) ...[
                    Text(
                      'Unsaved changes to $changed participant'
                      '${changed == 1 ? '' : 's'}',
                      key: const ValueKey('unsaved-count'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('discard-participants'),
                      onPressed: c.discardAll,
                      child: const Text('Discard'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
