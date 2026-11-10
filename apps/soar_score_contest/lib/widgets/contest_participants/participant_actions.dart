import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Invitation actions for a selection, or the actions of one explicit row.
///
/// A row (`rowId` set) gets a three-dot menu with Remove, Send and Copy; a
/// disabled item says why through its own tooltip. A selection of one pilot
/// gets an Invitations dropdown; several get a single Send button.
class ParticipantActions extends StatelessWidget {
  const ParticipantActions({
    super.key,
    this.rowId,
    required this.count,
    this.sendCount = 0,
    this.onSend,
    this.onCopy,
    this.onRemove,
    this.sendReason,
    this.copyReason,
    this.removeReason,
  });

  final String? rowId;

  /// How many rows the actions target.
  final int count;

  /// How many of them would get a new invitation.
  final int sendCount;
  final VoidCallback? onSend;
  final VoidCallback? onCopy;
  final VoidCallback? onRemove;

  /// Why each action is off, in words, or `null` when it is on.
  final String? sendReason;
  final String? copyReason;
  final String? removeReason;

  Widget _item({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    String? reason,
  }) {
    final item = MenuItemButton(
      key: key,
      leadingIcon: Icon(icon),
      onPressed: onPressed,
      child: Text(label),
    );
    return onPressed == null && reason != null
        ? Tooltip(message: reason, child: item)
        : item;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final row = rowId;
    final style = TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
    );
    if (row == null && count > 1) {
      return Tooltip(
        message: sendReason ?? '',
        child: TextButton.icon(
          key: const ValueKey('invitations-send'),
          style: style,
          onPressed: onSend,
          icon: const Icon(Icons.campaign, size: 18),
          label: Text(
            sendCount > 0
                ? l10n.invitationsMenuSendCount(sendCount)
                : l10n.invitationsMenuSend,
          ),
        ),
      );
    }
    return MenuAnchor(
      menuChildren: [
        if (row != null)
          _item(
            key: ValueKey('participant-remove-$row'),
            icon: Icons.person_remove_outlined,
            label: l10n.participantActionRemove,
            onPressed: onRemove,
            reason: removeReason,
          ),
        _item(
          key: ValueKey(
            row == null ? 'invitations-send' : 'participant-send-$row',
          ),
          icon: Icons.campaign,
          label: l10n.participantActionSend,
          onPressed: onSend,
          reason: sendReason,
        ),
        _item(
          key: ValueKey(
            row == null ? 'invitations-copy' : 'participant-copy-$row',
          ),
          icon: Icons.link,
          label: l10n.participantActionCopy,
          onPressed: onCopy,
          reason: copyReason,
        ),
      ],
      builder: (context, menu, _) {
        void toggle() => menu.isOpen ? menu.close() : menu.open();
        if (row != null) {
          return IconButton(
            key: ValueKey('participant-actions-$row'),
            tooltip: l10n.participantActions,
            onPressed: toggle,
            icon: const Icon(Icons.more_vert),
          );
        }
        return Tooltip(
          message: [?sendReason, ?copyReason].join(' '),
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
