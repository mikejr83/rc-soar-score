import 'package:flutter/material.dart';

import '../../services/participants/participant_row_style.dart';

/// A row's note line: an icon, the message and one action, in the error or
/// the tertiary container.
class ParticipantRowNoteView extends StatelessWidget {
  const ParticipantRowNoteView({
    super.key,
    required this.note,
    this.rowId,
    this.margin = EdgeInsets.zero,
  });

  final ParticipantRowNote note;

  /// The row it belongs to, for the widget key.
  final String? rowId;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final error = note.tone == ParticipantNoteTone.error;
    final background = error ? scheme.errorContainer : scheme.tertiaryContainer;
    final foreground = error
        ? scheme.onErrorContainer
        : scheme.onTertiaryContainer;
    final action = note.onAction == null || note.actionLabel == null
        ? null
        : TextButton.icon(
            onPressed: note.onAction,
            style: TextButton.styleFrom(foregroundColor: foreground),
            icon: note.actionIcon == null
                ? const SizedBox.shrink()
                : Icon(note.actionIcon, size: 18),
            label: Text(note.actionLabel!),
          );
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: ValueKey('note-${rowId ?? ''}'),
        margin: margin,
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(
              error ? Icons.error : Icons.sync_problem,
              size: 20,
              color: foreground,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                note.text,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: foreground),
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
