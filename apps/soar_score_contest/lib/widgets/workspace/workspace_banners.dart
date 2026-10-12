import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'workspace_banner.dart';

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

  @override
  Widget build(BuildContext context) {
    final copyTime = localCopyTime;
    final change = staleChange;
    return Column(
      key: const ValueKey('workspace-banners'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (change != null)
          WorkspaceBanner(
            key: const ValueKey('workspace-banner-stale'),
            kind: WorkspaceBannerKind.alert,
            icon: Icons.sync_problem,
            text:
                "Your change to $change wasn't applied. This page is out of date.",
            actionLabel: 'Refresh',
            onAction: onRefresh,
          ),
        if (copyTime != null)
          WorkspaceBanner(
            key: const ValueKey('workspace-banner-unavailable'),
            kind: WorkspaceBannerKind.alert,
            icon: Icons.cloud_off,
            text:
                "Can't reach the Soar Score server. Showing this device's copy "
                'from $copyTime. Scoring still works here and will sync; '
                'publishing, visibility and delisting are off until the '
                'server is back.',
            actionLabel: 'Try again',
            onAction: onRetry,
          ),
        if (offline)
          WorkspaceBanner(
            key: const ValueKey('workspace-banner-offline'),
            kind: WorkspaceBannerKind.status,
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
}
