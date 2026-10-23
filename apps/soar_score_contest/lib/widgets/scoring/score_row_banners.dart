import 'package:flutter/material.dart';

import '../../services/scoring/row_save.dart';
import '../page_states/page_banner.dart';

/// A line of text with an icon, and an optional button, under the entry
/// fields. A question or a message, never a modal.
class ScoreInlineNote extends StatelessWidget {
  const ScoreInlineNote({
    super.key,
    required this.icon,
    required this.text,
    this.kind = PageBannerKind.neutral,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    this.actionOrder = 9.5,
  });

  final IconData icon;
  final String text;
  final PageBannerKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  /// Where the action sits in the Tab order of the row: after the penalties
  /// and before Save row.
  final double actionOrder;

  @override
  Widget build(BuildContext context) => _RowBanner(
    kind: kind,
    icon: icon,
    text: text,
    actions: [
      if (actionLabel != null)
        PageBannerAction(
          actionLabel!,
          onAction,
          key: actionKey,
          focusOrder: actionOrder,
        ),
    ],
  );
}

/// An error message over the entry fields: the error container, an error icon
/// and the full reason. Announced to screen readers.
class ScoreErrorBanner extends StatelessWidget {
  const ScoreErrorBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) =>
      _RowBanner(kind: PageBannerKind.alert, icon: Icons.error, text: text);
}

/// A [PageBanner] card under the entry fields of a score row.
class _RowBanner extends StatelessWidget {
  const _RowBanner({
    required this.kind,
    required this.icon,
    required this.text,
    this.bannerKey,
    this.actions = const [],
  });

  final PageBannerKind kind;
  final IconData icon;
  final String text;
  final Key? bannerKey;
  final List<PageBannerAction> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: PageBanner(
      key: bannerKey,
      kind: kind,
      shape: PageBannerShape.card,
      icon: icon,
      text: text,
      actions: actions,
    ),
  );
}

/// What a failed or conflicting save says, and what can be done. The typed
/// values are always kept.
class ScoreSaveBanner extends StatelessWidget {
  const ScoreSaveBanner({
    super.key,
    required this.save,
    required this.mine,
    required this.theirs,
    required this.onRetry,
    required this.onRefresh,
    required this.onKeepMine,
    required this.onTakeTheirs,
  });

  final RowSave save;
  final Map<String, Object?> mine;
  final Map<String, Object?>? theirs;
  final VoidCallback onRetry;
  final VoidCallback onRefresh;
  final VoidCallback onKeepMine;
  final VoidCallback onTakeTheirs;

  static String _summary(Map<String, Object?>? c) {
    if (c == null || c.isEmpty) return 'nothing entered';
    return c.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }

  @override
  Widget build(BuildContext context) {
    switch (save.kind) {
      case RowSaveKind.stale:
        return _RowBanner(
          bannerKey: const ValueKey('score-stale'),
          kind: PageBannerKind.status,
          icon: Icons.sync_problem,
          text:
              'This row changed since you opened it. Yours: '
              '${_summary(mine)}. Newer: ${_summary(theirs)}.',
          actions: [
            PageBannerAction(
              'Keep mine',
              onKeepMine,
              emphasis: PageBannerEmphasis.filled,
              key: const ValueKey('score-keep-mine'),
            ),
            PageBannerAction(
              'Take the newer',
              onTakeTheirs,
              emphasis: PageBannerEmphasis.outlined,
              key: const ValueKey('score-take-theirs'),
            ),
          ],
        );
      case RowSaveKind.failed:
        return _RowBanner(
          bannerKey: const ValueKey('score-save-failed'),
          kind: PageBannerKind.alert,
          icon: Icons.error_outline,
          text: 'Not saved. ${save.message ?? ''} Your values are kept.',
          actions: [
            if (save.networkProblem)
              PageBannerAction(
                'Retry',
                onRetry,
                emphasis: PageBannerEmphasis.filled,
                key: const ValueKey('score-retry'),
              )
            else
              PageBannerAction(
                'Refresh',
                onRefresh,
                emphasis: PageBannerEmphasis.outlined,
                key: const ValueKey('score-refresh'),
              ),
          ],
        );
      case RowSaveKind.refused:
        return ScoreInlineNote(
          icon: Icons.error_outline,
          kind: PageBannerKind.alert,
          text:
              'Refused: ${save.message ?? 'the entry was not accepted'}. '
              'Your values are kept.',
          actionLabel: 'Refresh',
          onAction: onRefresh,
        );
      case RowSaveKind.idle:
      case RowSaveKind.saving:
        return const SizedBox.shrink();
    }
  }
}
