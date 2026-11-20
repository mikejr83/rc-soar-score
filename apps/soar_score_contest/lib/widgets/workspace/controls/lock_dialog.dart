import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';

/// Asks the director to confirm locking administration, naming what the lock
/// blocks. Resolves to true when confirmed.
Future<bool> confirmLock(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        key: const ValueKey('lock-dialog'),
        title: Text(l10n.workspaceLockTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.workspaceLockLifecycle),
            const SizedBox(height: 12),
            Text(l10n.workspaceLockRejected),
            const SizedBox(height: 4),
            Text(l10n.workspaceLockConfigItem),
            Text(l10n.workspaceLockParticipantsItem),
            Text(l10n.workspaceLockMatrixItem),
            Text(l10n.workspaceLockScoresItem),
            const SizedBox(height: 12),
            Text(l10n.workspaceLockBody),
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('lock-dialog-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            key: const ValueKey('lock-dialog-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.workspaceLockButton),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
