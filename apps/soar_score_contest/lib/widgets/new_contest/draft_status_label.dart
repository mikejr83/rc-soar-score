import 'package:flutter/material.dart';

import '../../services/new_contest/contest_draft_store.dart';
import '../../services/preferences/director_time.dart';

/// The quiet draft state in the shell header while the wizard is open:
/// `Draft saved · 10:42`, or `Draft not saved` when the last save failed.
class DraftStatusLabel extends StatelessWidget {
  const DraftStatusLabel({super.key, required this.store});

  final ContestDraftStore store;

  static const String explanation =
      'One draft at a time. It is kept on this device and isn’t listed with '
      'contests.';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final savedAt = store.savedAt;
      final failed = store.saveFailed;
      if (!failed && savedAt == null) {
        return const SizedBox.shrink();
      }
      final color = failed ? scheme.error : scheme.onSurfaceVariant;
      final time = failed ? '' : DirectorTime.clockOf(context)(savedAt!);
      final narrow = MediaQuery.sizeOf(context).width < 1100;
      final text = failed
          ? 'Draft not saved'
          : narrow
          ? 'Draft saved $time'
          : 'Draft saved · $time';
      return Tooltip(
        message: explanation,
        child: Semantics(
          liveRegion: true,
          child: Row(
            key: const ValueKey('draft-status'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                failed ? Icons.sync_problem : Icons.check_circle_outline,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
