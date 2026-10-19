import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../../services/reports/report_availability.dart';
import '../../services/reports/report_kind.dart';
import 'report_thumbnail.dart';

/// What the card shows after Open was pressed.
enum CardOpenState {
  /// Nothing to say.
  none,

  /// The report opened in its own tab; the card says so briefly.
  opened,

  /// The browser blocked the new tab; Try again or Open here.
  blocked,
}

/// One report on the reports page: a thumbnail, the title and brief, what it
/// needs, any warning, and a single Open button. A report that cannot be
/// produced keeps its place, disables Open and says why in text beside it.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.kind,
    required this.availability,
    required this.compact,
    required this.onOpen,
    required this.onAction,
    this.openState = CardOpenState.none,
    this.onOpenHere,
  });

  final ReportKind kind;
  final ReportAvailability availability;

  /// A compact window uses a smaller thumbnail and tighter spacing.
  final bool compact;
  final VoidCallback onOpen;
  final ValueChanged<ReportAction> onAction;
  final CardOpenState openState;

  /// Opens the report in this window, after the browser blocked a new tab.
  final VoidCallback? onOpenHere;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = availability.isAvailable;
    final reason = availability.reason;
    final action = availability.action;
    return Card(
      key: ValueKey('report-card-${kind.key}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: compact ? 12 : 16,
          children: [
            ReportThumbnail(
              kind: kind,
              size: compact ? 72 : 112,
              faded: !available,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Semantics(
                    header: true,
                    child: Text(kind.title, style: theme.textTheme.titleLarge),
                  ),
                  Text(
                    kind.brief,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  _Facts(kind: kind),
                  for (final note in availability.notes)
                    _NoteBox(note: note, onAction: onAction),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        key: ValueKey('report-open-${kind.key}'),
                        onPressed: available ? onOpen : null,
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Open'),
                      ),
                      if (reason != null && action != null)
                        _Reason(
                          key: ValueKey('report-reason-${kind.key}'),
                          reason: reason,
                          action: action,
                          onAction: onAction,
                        ),
                    ],
                  ),
                  if (openState == CardOpenState.opened)
                    Semantics(
                      liveRegion: true,
                      child: Row(
                        key: ValueKey('report-opened-${kind.key}'),
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: AppStatusColors.getSuccess(
                              theme.brightness == Brightness.dark,
                            ),
                          ),
                          const Text('Opened in a new tab'),
                        ],
                      ),
                    ),
                  if (openState == CardOpenState.blocked)
                    _BlockedNotice(
                      key: ValueKey('report-blocked-${kind.key}'),
                      onTryAgain: onOpen,
                      onOpenHere: onOpenHere,
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

/// The browser blocked the new tab: Try again, or Open here (this window, with
/// a way back).
class _BlockedNotice extends StatelessWidget {
  const _BlockedNotice({super.key, required this.onTryAgain, this.onOpenHere});

  final VoidCallback onTryAgain;
  final VoidCallback? onOpenHere;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.tab_unselected, color: scheme.onSurfaceVariant),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: 160, maxWidth: 360),
                child: Text(
                  'Your browser blocked the new tab. Allow pop-ups for Soar '
                  'Score, or open the report here and use Back to return.',
                ),
              ),
              TextButton(onPressed: onTryAgain, child: const Text('Try again')),
              FilledButton.tonal(
                onPressed: onOpenHere,
                child: const Text('Open here'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.kind});

  final ReportKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    Widget fact(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(icon, size: 16, color: muted),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        fact(
          Icons.scoreboard_outlined,
          kind.needsScores ? 'Needs scores' : 'No scores needed',
        ),
        fact(Icons.grid_view, 'Needs a matrix'),
      ],
    );
  }
}

/// The text reason an unavailable report gives, with the link that fixes it.
class _Reason extends StatelessWidget {
  const _Reason({
    super.key,
    required this.reason,
    required this.action,
    required this.onAction,
  });

  final String reason;
  final ReportAction action;
  final ValueChanged<ReportAction> onAction;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(Icons.block, size: 18, color: muted),
        Text(reason),
        TextButton.icon(
          onPressed: () => onAction(action),
          icon: const Icon(Icons.chevron_right, size: 18),
          iconAlignment: IconAlignment.end,
          label: Text(action.label),
        ),
      ],
    );
  }
}

/// A warning on an available report: an icon, a bold lead and a border, never
/// colour alone.
class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.note, required this.onAction});

  final ReportNote note;
  final ValueChanged<ReportAction> onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final action = note.action;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppStatusColors.getWarning(dark)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: scheme.onTertiaryContainer),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 20,
                  color: scheme.onTertiaryContainer,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 160,
                    maxWidth: 420,
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: note.lead,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(text: ' ${note.text}'),
                      ],
                    ),
                  ),
                ),
                if (action != null)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onTertiaryContainer,
                    ),
                    onPressed: () => onAction(action),
                    child: Text(
                      action.label,
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
