import 'package:flutter/material.dart';

import '../state/connectivity_state.dart';

/// A connectivity status indicator chip for the app bar.
///
/// Shows a colored icon and text label reflecting the current liveness of an
/// indicator. Tapping opens a detail dialog with the last observed time and a
/// Retry action.
class ConnectivityStatusIndicator extends StatelessWidget {
  /// The indicator to display.
  final IndicatorState state;

  /// The label shown in the chip (e.g. 'Internet' or 'API').
  final String label;

  /// The icon to use for the chip.
  final IconData icon;

  /// The connectivity state that owns this indicator; used for Retry.
  final ConnectivityState connectivity;

  const ConnectivityStatusIndicator({
    super.key,
    required this.state,
    required this.label,
    required this.icon,
    required this.connectivity,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    return Tooltip(
      message: '$label: ${state.label}',
      child: InkWell(
        onTap: () => _showDetailDialog(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (state.status) {
      case ConnectivityStatus.unknown:
        return theme.colorScheme.outline;
      case ConnectivityStatus.checking:
        return theme.colorScheme.primary;
      case ConnectivityStatus.available:
        return Colors.green;
      case ConnectivityStatus.unavailable:
        return Colors.red;
    }
  }

  void _showDetailDialog(BuildContext context) {
    final theme = Theme.of(context);
    final lastChecked = state.lastCheckedAt;
    final detail = state.detail;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text('$label status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: _statusColor(context)),
                const SizedBox(width: 8),
                Text(state.label, style: theme.textTheme.titleSmall),
              ],
            ),
            if (lastChecked != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Last checked: ${lastChecked.toLocal().toIso8601String()}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (detail != null && detail.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(detail, style: theme.textTheme.bodySmall),
              ),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              connectivity.retry();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
