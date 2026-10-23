import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

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
      final pending = summary?.pendingChanges ?? 0;
      return ViewerBanner(
        kind: ViewerBannerKind.neutral,
        icon: Icons.cloud_off,
        lead: 'Offline.',
        text: pending == 0
            ? 'Produced from data on this device.'
            : 'Produced from data on this device. $pending '
                  '${pending == 1 ? 'change is' : 'changes are'} not yet '
                  'synced.',
        actions: [
          if (sync.available)
            PageBannerAction(
              'Open Sync',
              onOpenSync,
              emphasis: PageBannerEmphasis.outlined,
            ),
        ],
      );
    },
  );
}
