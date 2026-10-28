import 'package:flutter/material.dart';

import '../../services/contest_participants/participants_controller.dart';
import '../../services/contest_participants/stored_participant.dart';

/// The Save control, docked at the bottom of the page like the configuration
/// page's bar and always there: what the state is (changes waiting, nothing
/// to save, what stops a save) on the left, `Discard` and `Save changes` on
/// the right.
///
/// Edits wait here until Save; adding and removing people act at once from
/// the toolbar above the list. After a save that left rows unsaved, a summary
/// names them above the bar's content.
class ParticipantsSaveBar extends StatelessWidget {
  const ParticipantsSaveBar({
    super.key,
    required this.controller,
    required this.onShowRow,
    required this.onSave,
  });

  final ParticipantsController controller;

  /// Saves the changed rows.
  final VoidCallback onSave;

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
    final failed = c.failedRows;
    final plural = changed == 1 ? '' : 's';

    // The state, as an icon, a title, an optional sentence and an optional
    // link that fixes it. Icon and words carry the meaning, not colour.
    final IconData icon;
    final String title;
    final String? sub;
    final Color color;
    String? linkLabel;
    VoidCallback? onLink;
    Key titleKey = const ValueKey('save-reason');
    if (busy) {
      icon = Icons.sync;
      title = 'Saving $changed participant$plural…';
      sub = 'Rows are locked until it finishes.';
      color = scheme.onSurface;
    } else if (stale.isNotEmpty) {
      icon = Icons.sync_problem;
      title = 'Someone changed this participant. Refresh to continue.';
      sub = null;
      color = scheme.onSurface;
      linkLabel = 'Refresh';
      onLink = () => c.refreshRow(stale.first);
    } else if (invalid.isNotEmpty) {
      icon = Icons.error;
      title =
          'Fix ${invalid.length} row${invalid.length == 1 ? '' : 's'} before '
          'saving.';
      sub = null;
      color = scheme.error;
      linkLabel = 'Show row';
      onLink = () => onShowRow(invalid.first);
    } else if (changed > 0) {
      icon = Icons.edit_note;
      title = 'Unsaved changes to $changed participant$plural';
      sub = 'Each participant saves on its own.';
      color = scheme.onSurface;
      titleKey = const ValueKey('unsaved-count');
    } else {
      icon = Icons.check;
      title = 'No changes to save.';
      sub = null;
      color = scheme.onSurface;
    }
    final off = busy || stale.isNotEmpty || invalid.isNotEmpty || changed == 0;

    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 3,
      child: Semantics(
        container: true,
        label: 'Save changes',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (busy)
              LinearProgressIndicator(
                minHeight: 4,
                semanticsLabel: 'Saving participants',
                backgroundColor: scheme.primaryContainer,
              ),
            if (failed.isNotEmpty && !busy) _failureSummary(context, failed),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 16, 12),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 280,
                      maxWidth: 640,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          container: true,
                          liveRegion: true,
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Icon(icon, size: 22, color: color),
                              Text(
                                title,
                                key: titleKey,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: color,
                                ),
                              ),
                              if (linkLabel != null && onLink != null)
                                TextButton(
                                  key: const ValueKey('save-reason-link'),
                                  onPressed: onLink,
                                  child: Text(linkLabel),
                                ),
                            ],
                          ),
                        ),
                        if (sub != null)
                          Text(sub, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (changed > 0 && !busy)
                        OutlinedButton(
                          key: const ValueKey('discard-participants'),
                          onPressed: c.discardAll,
                          child: const Text('Discard changes'),
                        ),
                      FilledButton.icon(
                        key: const ValueKey('save-participants'),
                        onPressed: off ? null : onSave,
                        icon: busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(busy ? 'Saving…' : 'Save changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// After a save that left rows unsaved: how many went through and which
  /// did not, with a link to each row.
  Widget _failureSummary(BuildContext context, List<StoredParticipant> failed) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: const ValueKey('save-summary'),
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${controller.savedCount} saved. ${failed.length} not '
                    'saved. Their typed values are kept.',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final row in failed)
                        TextButton(
                          onPressed: () => onShowRow(row),
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.onErrorContainer,
                          ),
                          child: Text(
                            '${row.name}: '
                            '${controller.stateOf(row.rowId).message ?? ''}',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
