import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../page_states/page_banner.dart';

/// The banner area above the workspace sections: one banner per cause, so a
/// stale page and an offline device can show together.
class WorkspaceBanners extends StatelessWidget {
  const WorkspaceBanners({
    super.key,
    this.offline = false,
    this.keepsLocalData = !kIsWeb,
    this.localCopyTime,
    this.onRetry,
    this.staleChange,
    this.onRefresh,
    this.importNote,
  });

  /// The connectivity monitor says the device is offline.
  final bool offline;

  /// The build keeps contest data on the device (native). The web build does
  /// not, so offline there promises nothing beyond the page on screen.
  final bool keepsLocalData;

  /// When the local copy on show was taken, formatted for the director;
  /// `null` when the server is reachable. Nothing sets it before the local
  /// store lands (#319).
  final String? localCopyTime;
  final VoidCallback? onRetry;

  /// What a rejected change was about ("administration"), when a transition
  /// came back 409.
  final String? staleChange;
  final VoidCallback? onRefresh;

  /// What the contest's GliderScore import left out; `null` for a contest
  /// that was not imported.
  final ImportedContestNote? importNote;

  @override
  Widget build(BuildContext context) {
    final copyTime = localCopyTime;
    final change = staleChange;
    final imported = importNote;
    return Column(
      key: const ValueKey('workspace-banners'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (change != null)
          PageBanner(
            key: const ValueKey('workspace-banner-stale'),
            kind: PageBannerKind.alert,
            icon: Icons.sync_problem,
            text:
                "Your change to $change wasn't applied. This page is out of date.",
            actionLabel: 'Refresh',
            onAction: onRefresh,
          ),
        if (copyTime != null)
          PageBanner(
            key: const ValueKey('workspace-banner-unavailable'),
            kind: PageBannerKind.alert,
            icon: Icons.cloud_off,
            text:
                "Can't reach the Soar Score server. Showing this device's copy "
                'from $copyTime. Scoring still works here and will sync; '
                'publishing, visibility and delisting are off until the '
                'server is back.',
            actionLabel: 'Try again',
            onAction: onRetry,
          ),
        if (imported != null) _importedBanner(context, imported),
        if (offline)
          PageBanner(
            key: const ValueKey('workspace-banner-offline'),
            kind: PageBannerKind.status,
            icon: Icons.wifi_off,
            text: keepsLocalData
                ? "Offline. Scoring and the other controls keep working on "
                      "this device and sync when you're back. Publishing, "
                      'visibility and delisting need a connection.'
                : "Offline. Changes can't be saved until you're back online; "
                      'what is on screen may be out of date.',
          ),
      ],
    );
  }

  Widget _importedBanner(BuildContext context, ImportedContestNote note) {
    final l10n = AppLocalizations.of(context);
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(note.importedAt.toLocal());
    final lines = [
      if (note.drawImported)
        l10n.importedContestNoteDraw
      else
        l10n.importedContestNoteNoDraw,
      if (note.drawImported && !note.lanesKept) l10n.importedContestNoteNoLanes,
      l10n.importedContestNoteBody,
    ];
    return PageBanner(
      key: const ValueKey('workspace-banner-imported'),
      kind: PageBannerKind.info,
      icon: Icons.history,
      title: l10n.importedContestNoteTitle(date),
      text: lines.join(' '),
    );
  }
}
