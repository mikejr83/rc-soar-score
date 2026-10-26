import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../l10n/app_localizations.dart';
import '../services/preferences/director_time.dart';
import '../services/storage/storage_monitor.dart';

/// The status bar's indicator for the storage on this device: an icon and a
/// text label, with a detail dialog on tap. State is never shown by color
/// alone.
class StorageIndicator extends StatelessWidget {
  const StorageIndicator(this.monitor, {super.key});

  final StorageMonitor monitor;

  static IconData _icon(ConnectivityStatus status) => switch (status) {
    ConnectivityStatus.unknown => Icons.help_outline,
    ConnectivityStatus.checking => Icons.sync,
    ConnectivityStatus.available => Icons.storage,
    ConnectivityStatus.unavailable => Icons.error_outline,
  };

  static String _label(AppLocalizations l10n, ConnectivityStatus status) =>
      switch (status) {
        ConnectivityStatus.unknown ||
        ConnectivityStatus.checking => l10n.storageStatusChecking,
        ConnectivityStatus.available => l10n.storageStatusAvailable,
        ConnectivityStatus.unavailable => l10n.storageStatusUnavailable,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: monitor,
      builder: (context, _) {
        final status = monitor.status;
        final label = _label(l10n, status);
        final text = l10n.storageIndicatorTooltip(
          l10n.storageIndicatorName,
          label,
        );
        return Tooltip(
          message: text,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Semantics(
              label: l10n.storageIndicatorName,
              value: label,
              container: true,
              button: true,
              excludeSemantics: true,
              onTap: () => _show(context),
              child: GestureDetector(
                key: const ValueKey('storage-chip'),
                onTap: () => _show(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon(status), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.storageIndicatorName} · $label',
                      key: const ValueKey('storage-label'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => _StorageDetailDialog(monitor),
    );
  }
}

/// The storage status, when it last answered, why a check failed, and a retry.
class _StorageDetailDialog extends StatelessWidget {
  const _StorageDetailDialog(this.monitor);

  final StorageMonitor monitor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final time = DirectorTime.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      key: const ValueKey('storage-dialog'),
      title: Text(l10n.storageIndicatorName),
      content: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: monitor,
          builder: (context, _) {
            final observed = monitor.lastObservedAt;
            final error = monitor.lastError;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.storageDetailStatus(
                    StorageIndicator._label(l10n, monitor.status),
                  ),
                  key: const ValueKey('storage-status'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.storageDetailLastObserved(
                    observed == null
                        ? l10n.storageNeverObserved
                        : time(observed),
                  ),
                  key: const ValueKey('storage-last-observed'),
                ),
                if (monitor.status == ConnectivityStatus.unavailable &&
                    error != null)
                  Text(
                    l10n.storageDetailError(error),
                    key: const ValueKey('storage-error'),
                  ),
                const SizedBox(height: 8),
                Text(l10n.storageDetailNote, style: theme.textTheme.bodySmall),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('storage-retry'),
          onPressed: () => unawaited(monitor.retry()),
          child: Text(l10n.storageRetry),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.storageDetailClose),
        ),
      ],
    );
  }
}
