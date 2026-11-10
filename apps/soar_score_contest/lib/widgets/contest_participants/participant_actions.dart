import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Invitation actions for a selection, or the actions of one explicit row.
class ParticipantActions extends StatelessWidget {
  const ParticipantActions({
    super.key,
    this.rowId,
    required this.count,
    this.onSend,
    this.onCopy,
    this.onRemove,
    this.reason,
  });

  final String? rowId;
  final int count;
  final VoidCallback? onSend;
  final VoidCallback? onCopy;
  final VoidCallback? onRemove;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final row = rowId;
    final style = TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
    );
    if (row == null && count > 1) {
      return Tooltip(
        message: reason ?? '',
        child: TextButton.icon(
          key: const ValueKey('invitations-send'),
          style: style,
          onPressed: onSend,
          icon: const Icon(Icons.campaign, size: 18),
          label: Text(l10n.invitationsMenuSend),
        ),
      );
    }
    return MenuAnchor(
      menuChildren: [
        if (row != null)
          MenuItemButton(
            key: ValueKey('participant-remove-$row'),
            leadingIcon: const Icon(Icons.person_remove_outlined),
            onPressed: onRemove,
            child: Text(l10n.participantActionRemove),
          ),
        MenuItemButton(
          key: ValueKey(
            row == null ? 'invitations-send' : 'participant-send-$row',
          ),
          leadingIcon: const Icon(Icons.campaign),
          onPressed: onSend,
          child: Text(l10n.participantActionSend),
        ),
        MenuItemButton(
          key: ValueKey(
            row == null ? 'invitations-copy' : 'participant-copy-$row',
          ),
          leadingIcon: const Icon(Icons.link),
          onPressed: onCopy,
          child: Text(l10n.participantActionCopy),
        ),
      ],
      builder: (context, menu, _) {
        void toggle() => menu.isOpen ? menu.close() : menu.open();
        if (row != null) {
          return IconButton(
            key: ValueKey('participant-actions-$row'),
            tooltip: [l10n.participantActions, ?reason].join('\n'),
            onPressed: toggle,
            icon: const Icon(Icons.more_vert),
          );
        }
        return Tooltip(
          message: reason ?? '',
          child: TextButton.icon(
            key: const ValueKey('invitations-menu'),
            style: style,
            onPressed: toggle,
            icon: const Icon(Icons.qr_code_2, size: 18),
            label: Text(l10n.invitationsMenu),
          ),
        );
      },
    );
  }
}
