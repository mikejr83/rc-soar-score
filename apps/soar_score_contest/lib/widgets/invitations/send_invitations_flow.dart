import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../connectivity_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/reports/pilot_cards/pilot_invitations.dart';
import '../reports/pilot_cards/pilot_cards_dialogs.dart';

/// Whether the app can reach the internet now: not known to be offline.
bool invitationsOnline(BuildContext context) =>
    appConnectivityOf(context)?.internetStatus !=
    ConnectivityStatus.unavailable;

/// Why invitations cannot be sent for this contest now, in words, or `null`
/// when they can. The cards report, the workspace and the participants list
/// share it. [online] is the connectivity now, read again at every use, so a
/// network change turns the action off instead of failing a request.
String? invitationsUnavailableText(
  AppLocalizations l10n,
  PilotInvitations invitations, {
  bool online = true,
}) => !invitations.synchronized
    ? l10n.pilotCardsReminderUnsynced
    : !online
    ? l10n.invitationsOffline
    : sendUnavailableText(l10n, invitations);

/// Confirms, then creates invitations for [participations] (those without
/// one) and says how it went in a snack bar. Never emails.
///
/// This is the cards' own send, reached from the workspace and the
/// participants list. Connectivity is checked again here, so an action that
/// was on when it was drawn does not send into a lost connection.
Future<bool> sendInvitationsWithConfirmation(
  BuildContext context,
  PilotInvitationSession session,
  List<Id> participations,
) async {
  if (participations.isEmpty) return false;
  if (!invitationsOnline(context)) {
    _say(context, AppLocalizations.of(context).invitationsOffline);
    return false;
  }
  if (!await confirmSendInvitations(context, participations.length)) {
    return false;
  }
  final ok = await session.send(participations);
  // The page may have been left while the request ran; the send itself is
  // finished either way.
  if (!context.mounted) return ok;
  final l10n = AppLocalizations.of(context);
  _say(
    context,
    ok
        ? l10n.invitationsSentSnack(participations.length)
        : session.phase == InvitationPhase.sentNotLoaded
        ? l10n.invitationsSentNotLoadedSnack
        : l10n.invitationsSendFailedSnack,
  );
  return ok;
}

void _say(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const ValueKey('invitations-snackbar'),
        content: Text(message),
      ),
    );
}
