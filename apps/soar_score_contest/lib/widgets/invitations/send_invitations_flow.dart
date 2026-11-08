import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/reports/pilot_cards/pilot_invitations.dart';
import '../reports/pilot_cards/pilot_cards_dialogs.dart';

/// Why invitations cannot be sent for this contest now, in words, or `null`
/// when they can. The cards report and the workspace share it.
String? invitationsUnavailableText(
  AppLocalizations l10n,
  PilotInvitations invitations,
) => !invitations.synchronized
    ? l10n.pilotCardsReminderUnsynced
    : sendUnavailableText(l10n, invitations);

/// Confirms, then creates invitations for [participations] (those without
/// one) and says how it went in a snack bar. Never emails.
///
/// This is the cards' own send, reached from the workspace and the
/// participants list.
Future<bool> sendInvitationsWithConfirmation(
  BuildContext context,
  PilotInvitationSession session,
  List<Id> participations,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  if (participations.isEmpty ||
      !await confirmSendInvitations(context, participations.length)) {
    return false;
  }
  final ok = await session.send(participations);
  final message = ok
      ? l10n.invitationsSentSnack(participations.length)
      : session.phase == InvitationPhase.sentNotLoaded
      ? l10n.invitationsSentNotLoadedSnack
      : l10n.invitationsSendFailedSnack;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const ValueKey('invitations-snackbar'),
        content: Text(message),
      ),
    );
  return ok;
}
