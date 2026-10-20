import 'package:flutter/material.dart';

import '../../services/new_contest/draft_persistence.dart';
import '../../services/preferences/director_time.dart';

/// Asks whether to continue the draft stored by an earlier run or start
/// fresh. Returns `true` to continue and `false` to discard it.
///
/// It can't be dismissed without choosing, because starting fresh deletes the
/// stored draft. A draft that can't be read (saved by another version of the
/// app) can only be discarded.
Future<bool> showResumeDraftDialog(
  BuildContext context,
  StoredDraft stored,
) async {
  final readable = stored is FoundStoredDraft;
  final savedAt = switch (stored) {
    FoundStoredDraft(:final savedAt) => savedAt,
    UnreadableStoredDraft(:final savedAt) => savedAt,
    NoStoredDraft() => null,
  };
  final when = savedAt == null ? null : DirectorTime.of(context)(savedAt);
  final resume = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      key: const ValueKey('resume-draft-dialog'),
      icon: const Icon(Icons.edit_note),
      title: Text(readable ? 'Continue your draft?' : 'Discard your draft?'),
      content: SizedBox(
        width: 392,
        child: Text(
          readable
              ? 'You started a contest that isn’t created yet'
                    '${when == null ? '' : ' (last saved $when)'}. Continue '
                    'it, or start fresh and delete it.'
              : 'A draft saved${when == null ? '' : ' $when'} can’t be '
                    'opened by this version of the app. Discard it to '
                    'start a new contest.',
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('resume-draft-fresh'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(readable ? 'Start fresh' : 'Discard draft'),
        ),
        if (readable)
          FilledButton(
            key: const ValueKey('resume-draft-continue'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue draft'),
          ),
      ],
    ),
  );
  return resume ?? false;
}
