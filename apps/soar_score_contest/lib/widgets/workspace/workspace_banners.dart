import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
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
    final l10n = AppLocalizations.of(context);
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
            text: l10n.workspaceBannerStaleChange(change),
            actionLabel: l10n.workspaceBannerStaleRefresh,
            onAction: onRefresh,
          ),
        if (copyTime != null)
          PageBanner(
            key: const ValueKey('workspace-banner-unavailable'),
            kind: PageBannerKind.alert,
            icon: Icons.cloud_off,
            text: l10n.workspaceBannerUnreachable(copyTime),
            actionLabel: l10n.workspaceBannerTryAgain,
            onAction: onRetry,
          ),
        if (imported != null) _importedBanner(context, imported),
        if (offline)
          PageBanner(
            key: const ValueKey('workspace-banner-offline'),
            kind: PageBannerKind.status,
            icon: Icons.wifi_off,
            text: keepsLocalData
                ? l10n.workspaceBannerOfflineLocal
                : l10n.workspaceBannerOfflineNoLocal,
          ),
      ],
    );
  }

  Widget _importedBanner(BuildContext context, ImportedContestNote note) {
    final l10n = AppLocalizations.of(context);
    final date = DateFormat.yMMMd().format(note.importedAt.toLocal());
    final lines = [
      l10n.importedContestNoteBody,
      if (!note.lanesKept) l10n.importedContestNoteNoLanes,
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
