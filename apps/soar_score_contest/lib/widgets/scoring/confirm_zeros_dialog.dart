import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/scoring/scoring_row.dart';

/// Asks the director to confirm the rows that will be saved as zeros, the
/// same acknowledgement Save row asks for on one row. True when confirmed.
Future<bool> askConfirmZeros(
  BuildContext context,
  List<ScoringRow> rows,
) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.scoreSaveAllZeroTitle),
      content: Text(
        l10n.scoreSaveAllZeroBody(
          rows.length,
          rows.map((r) => r.pilot.name).join(', '),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('confirm-zeros-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.scoreSaveAllZeroCancel),
        ),
        FilledButton(
          key: const ValueKey('confirm-zeros-save'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.scoreSaveAllZeroConfirm),
        ),
      ],
    ),
  );
  return ok ?? false;
}
