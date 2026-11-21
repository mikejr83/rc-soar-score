import 'package:material_ui/material_ui.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../sync/sync_summary_builder.dart';
import '../../page_states/page_banner.dart';
import 'viewer_banner.dart';

/// The sheet was produced from this device's data. Says how many changes have
/// not synced and, where the build synchronizes, links to the sync page.
class ViewerOfflineBanner extends StatelessWidget {
  const ViewerOfflineBanner({
    super.key,
    required this.contestId,
    required this.onOpenSync,
  });

  final Id contestId;
  final VoidCallback onOpenSync;

  @override
  Widget build(BuildContext context) => SyncSummaryBuilder(
    scope: ContestScopeKey(contestId),
    builder: (context, sync, summary, syncing) {
      final l10n = AppLocalizations.of(context);
      final pending = summary?.pendingChanges ?? 0;
      return ViewerBanner(
        kind: ViewerBannerKind.neutral,
        icon: Icons.cloud_off,
        lead: l10n.viewerOffline,
        text: pending == 0
            ? l10n.viewerOfflineLocalOnly
            : l10n.viewerOfflinePending(
                pending,
                pending == 1 ? 'change is' : 'changes are',
              ),
        actions: [
          if (sync.available)
            PageBannerAction(
              l10n.viewerOpenSync,
              onOpenSync,
              emphasis: PageBannerEmphasis.outlined,
            ),
        ],
      );
    },
  );
}
