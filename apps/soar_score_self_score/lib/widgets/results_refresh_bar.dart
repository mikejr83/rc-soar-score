import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// Manual results reads; the timestamp describes the fetch on this device.
class ResultsRefreshBar extends StatelessWidget {
  const ResultsRefreshBar({
    required this.lastRefreshed,
    required this.loading,
    required this.onRefresh,
    super.key,
  });

  final DateTime? lastRefreshed;
  final bool loading;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final time = lastRefreshed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              time == null
                  ? strings.resultsRefreshHint
                  : strings.resultsLastRefreshed(
                      DateFormat.yMd(Localizations.localeOf(context).toString())
                          .add_Hms()
                          .format(time.toLocal()),
                    ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: loading ? null : onRefresh,
            icon: const Icon(Icons.refresh),
            label: Text(
              loading ? strings.refreshingResults : strings.refreshResults,
            ),
          ),
        ],
      ),
    );
  }
}
