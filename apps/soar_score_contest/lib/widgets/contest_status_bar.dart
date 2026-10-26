import 'package:flutter/material.dart';

import 'package:soar_score_core/soar_score_core.dart';

import '../connectivity_provider.dart';
import '../storage_provider.dart';
import 'connectivity_indicator.dart';
import 'storage_indicator.dart';
import 'sync/shell_sync_status.dart';

/// The shell's application status area (ticket 020 slot, ticket 023 content).
///
/// A thin bar spanning the full window width at the bottom of the shell:
/// the application status on the leading side and the connectivity
/// indicators on the trailing side. State is communicated by icon and text,
/// never by color alone.
class ContestStatusBar extends StatelessWidget {
  const ContestStatusBar({super.key, this.contest});

  /// The selected contest, whose sync status (last synced, changes waiting)
  /// the bar shows; none outside a contest.
  final Contest? contest;

  static const String status = 'Ready';

  /// The width, at the default text size, from which the bar fits one line.
  static const double _singleLineWidth = 720;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The indicators exist only when a bootstrap created the monitor (D5):
    // tests that pump the app without one see no chips.
    final monitor = appConnectivityOf(context);
    final storage = storageMonitorOf(context);
    final contest = this.contest;
    final indicators = <Widget>[
      if (storage != null) StorageIndicator(storage),
      if (monitor != null) ...[
        // Internet first; hidden when the host cannot report connectivity
        // at all (decision D8).
        if (monitor.supportsConnectivity)
          ConnectivityIndicator.internet(monitor),
        ConnectivityIndicator.api(monitor),
      ],
    ];

    return Container(
      key: const ValueKey('contest-status-bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final left = Wrap(
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                label: 'Application status',
                value: status,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Text(status, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (contest != null) ShellSyncStatus(contest: contest),
            ],
          );
          final right = Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: indicators,
          );
          // One line when there is room; the groups stack, and wrap inside,
          // in a narrow window or at a large text size.
          final scale = MediaQuery.textScalerOf(context).scale(1);
          if (constraints.maxWidth / scale < _singleLineWidth) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [left, right],
            );
          }
          return Row(
            children: [
              Expanded(
                child: Align(alignment: Alignment.centerLeft, child: left),
              ),
              ...indicators,
            ],
          );
        },
      ),
    );
  }
}
