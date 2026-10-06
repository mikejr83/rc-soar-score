import 'package:flutter/material.dart';

import '../connectivity_provider.dart';
import 'connectivity_indicator.dart';

/// The shell's application status area (ticket 020 slot, ticket 023 content).
///
/// A thin bar spanning the full window width at the bottom of the shell:
/// the application status on the leading side and the connectivity
/// indicators on the trailing side. State is communicated by icon and text,
/// never by color alone.
class ContestStatusBar extends StatelessWidget {
  const ContestStatusBar({super.key});

  static const String status = 'Ready';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The indicators exist only when a bootstrap created the monitor (D5):
    // tests that pump the app without one see no chips.
    final monitor = appConnectivityOf(context);
    final indicators = <Widget>[
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
      child: Row(
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
          const Spacer(),
          ...indicators,
        ],
      ),
    );
  }
}
