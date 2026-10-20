import 'dart:async';

import '../../services/preferences/director_time.dart';

import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../services/connectivity/app_connectivity.dart';

/// Which of the two indicators a [ConnectivityIndicator] renders.
enum ConnectivityIndicatorKind { internet, api }

/// The landing page's connectivity chips: a text-plus-icon indicator per
/// monitored connection, with a tap-to-open detail dialog.
///
/// State is communicated together by icon and text label — never by color
/// alone (accessibility rules of `plan/ui/contest-administration/`).
class ConnectivityIndicator extends StatelessWidget {
  const ConnectivityIndicator._({required this.kind, required this.monitor});

  final ConnectivityIndicatorKind kind;
  final AppConnectivity monitor;

  /// The internet indicator. The page hides it when the host cannot report
  /// connectivity at all (`supportsConnectivity == false`, decision D8).
  const ConnectivityIndicator.internet(AppConnectivity monitor)
    : this._(kind: ConnectivityIndicatorKind.internet, monitor: monitor);

  /// The remote API indicator.
  const ConnectivityIndicator.api(AppConnectivity monitor)
    : this._(kind: ConnectivityIndicatorKind.api, monitor: monitor);

  static IconData _icon(
    ConnectivityIndicatorKind kind,
    ConnectivityStatus status,
  ) => switch (status) {
    ConnectivityStatus.unknown => Icons.help_outline,
    ConnectivityStatus.checking => Icons.sync,
    ConnectivityStatus.available =>
      kind == ConnectivityIndicatorKind.internet ? Icons.wifi : Icons.cloud,
    ConnectivityStatus.unavailable =>
      kind == ConnectivityIndicatorKind.internet
          ? Icons.wifi_off
          : Icons.cloud_off,
  };

  static String _statusLabel(ConnectivityStatus status) => switch (status) {
    ConnectivityStatus.unknown => 'Unknown',
    ConnectivityStatus.checking => 'Checking',
    ConnectivityStatus.available => 'Online',
    ConnectivityStatus.unavailable => 'Offline',
  };

  String _name(ConnectivityIndicatorKind kind) => switch (kind) {
    ConnectivityIndicatorKind.internet => 'Internet connectivity',
    ConnectivityIndicatorKind.api => 'Remote API connectivity',
  };

  ConnectivityStatus _status() => kind == ConnectivityIndicatorKind.internet
      ? monitor.internetStatus
      : monitor.apiStatus;

  @override
  Widget build(BuildContext context) {
    // The chip re-reads the monitor on every notification so its icon and
    // label track live state (checking → online, …).
    return ListenableBuilder(
      listenable: monitor,
      builder: (context, _) {
        final name = _name(kind);
        final status = _status();
        final label = _statusLabel(status);
        return Tooltip(
          message: '$name: $label',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Semantics(
              label: name,
              value: label,
              container: true,
              button: true,
              child: GestureDetector(
                onTap: () => _showDetailDialog(context, kind, monitor),
                child: Row(
                  key: ValueKey('$name chip'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icon(kind, status),
                      key: ValueKey('$name icon'),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      key: ValueKey('$name label'),
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
}

/// The tap-to-open detail view required for every connectivity indicator by
/// `plan/ui/contest-administration/offline-ui.md`: the current status, when
/// it was last seen, (API only) when the last successful connection happened
/// and the last error, and a retry action.
///
/// The dialog stays open after "Retry now" and re-reads the monitor live: the
/// status and data lines are rebuilt on every monitor notification.
class _ConnectivityDetailDialog extends StatelessWidget {
  const _ConnectivityDetailDialog({required this.kind, required this.monitor});

  final ConnectivityIndicatorKind kind;
  final AppConnectivity monitor;

  @override
  Widget build(BuildContext context) {
    final timeText = DirectorTime.of(context);
    final theme = Theme.of(context);

    final content = ListenableBuilder(
      listenable: monitor,
      builder: (context, _) {
        final status = kind == ConnectivityIndicatorKind.internet
            ? monitor.internetStatus
            : monitor.apiStatus;
        final lines = <Widget>[
          Text(
            'Status: ${ConnectivityIndicator._statusLabel(status)}',
            key: const ValueKey('connectivity status'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
        ];

        if (kind == ConnectivityIndicatorKind.internet) {
          final lastObserved = monitor.internetLastObservedAt;
          lines.add(
            Text(
              'Last observed: '
              '${lastObserved == null ? 'Never' : timeText(lastObserved)}',
              key: const ValueKey('connectivity last observed'),
            ),
          );
          lines.add(
            const Text(
              'Network interface status as reported by the operating '
              'system.',
              key: ValueKey('connectivity note'),
              style: TextStyle(fontSize: 12),
            ),
          );
        } else {
          final lastSuccessful = monitor.apiLastSuccessfulAt;
          lines.add(
            Text(
              'Last successful connection: '
              '${lastSuccessful == null ? 'Never' : timeText(lastSuccessful)}',
              key: const ValueKey('connectivity last successful'),
            ),
          );
          lines.add(
            Text(
              'Target: ${monitor.apiTarget}',
              key: const ValueKey('connectivity target'),
              style: theme.textTheme.bodySmall,
            ),
          );
          if (status == ConnectivityStatus.unavailable &&
              monitor.apiLastError != null) {
            lines.add(
              Text(
                'Error: ${monitor.apiLastError}',
                key: const ValueKey('connectivity error'),
              ),
            );
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines,
        );
      },
    );

    return AlertDialog(
      title: Text(
        kind == ConnectivityIndicatorKind.internet
            ? 'Internet connectivity'
            : 'Remote API connectivity',
      ),
      content: SingleChildScrollView(child: content),
      actions: [
        TextButton(
          onPressed: () {
            if (kind == ConnectivityIndicatorKind.internet) {
              unawaited(monitor.retryInternet());
            } else {
              monitor.retryApi();
            }
          },
          child: const Text('Retry now'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

void _showDetailDialog(
  BuildContext context,
  ConnectivityIndicatorKind kind,
  AppConnectivity monitor,
) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) =>
        _ConnectivityDetailDialog(kind: kind, monitor: monitor),
  );
}
