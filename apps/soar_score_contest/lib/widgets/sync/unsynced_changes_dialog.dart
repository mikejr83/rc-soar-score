import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Asks before an action that would lose changes that have not reached the
/// service (resetting local data, replacing the installation), and returns
/// whether to go on. Returns true without asking when nothing is waiting.
Future<bool> confirmDiscardUnsynced(
  BuildContext context, {
  required int pendingChanges,
}) async {
  if (pendingChanges <= 0) return true;
  final l10n = AppLocalizations.of(context);
  final answer = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('unsynced-changes-dialog'),
      icon: const Icon(Icons.warning_amber_rounded),
      title: Text(l10n.unsyncedWarningTitle),
      content: Text(l10n.unsyncedWarningBody(pendingChanges)),
      actions: [
        TextButton(
          key: const ValueKey('unsynced-cancel'),
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.unsyncedWarningCancel),
        ),
        TextButton(
          key: const ValueKey('unsynced-continue'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.unsyncedWarningContinue),
        ),
      ],
    ),
  );
  return answer ?? false;
}
