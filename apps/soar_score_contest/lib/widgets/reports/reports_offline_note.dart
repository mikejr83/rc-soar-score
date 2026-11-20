import 'package:material_ui/material_ui.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../../l10n/app_localizations.dart';
import '../sync/sync_summary_builder.dart';

/// Tells the director that reports come from this device's data, with how
/// many changes have not synced yet and, where the build synchronizes, a link
/// to the sync page.
class ReportsOfflineNote extends StatelessWidget {
  const ReportsOfflineNote({
    super.key,
    required this.contestId,
    required this.onOpenSync,
  });

  final Id contestId;
  final VoidCallback? onOpenSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = AppStatusColors.getWarning(
      theme.brightness == Brightness.dark,
    );
    return SyncSummaryBuilder(
      scope: ContestScopeKey(contestId),
      builder: (context, sync, summary, syncing) {
        final l10n = AppLocalizations.of(context);
        final pending = summary?.pendingChanges ?? 0;
        final changes = pending == 0
            ? l10n.reportsOfflineLocalOnly
            : l10n.reportsOfflinePending(
                pending,
                pending == 1 ? 'change' : 'changes',
              );
        return DecoratedBox(
          key: const ValueKey('reports-offline-note'),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 20, color: warning),
                Text('$changes ${l10n.reportsOfflineSuffix}'),
                if (sync.available && onOpenSync != null)
                  TextButton.icon(
                    onPressed: onOpenSync,
                    icon: const Icon(Icons.chevron_right, size: 18),
                    iconAlignment: IconAlignment.end,
                    label: Text(l10n.reportsOpenSync),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
