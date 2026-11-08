import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../connectivity_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/reports/pilot_cards/pilot_invitations.dart';

/// Why the hosted server cannot be reached now, in words, or `null` when it
/// can (or nothing is known). Invitations need the hosted server, so both
/// the internet and the server being down turn sending off. The cards, the
/// workspace and the participants list share it and read it again at every
/// use, so a network change turns the action off instead of failing a request.
String? invitationsUnreachableText(
  BuildContext context,
  AppLocalizations l10n,
) {
  final monitor = appConnectivityOf(context);
  if (monitor == null) return null;
  if (monitor.internetStatus == ConnectivityStatus.unavailable) {
    return l10n.invitationsOffline;
  }
  if (monitor.apiStatus == ConnectivityStatus.unavailable) {
    return l10n.invitationsServerUnreachable;
  }
  return null;
}

/// Whether the hosted server can be reached now (see
/// [invitationsUnreachableText]).
bool invitationsReachable(BuildContext context) {
  final monitor = appConnectivityOf(context);
  return monitor == null ||
      (monitor.internetStatus != ConnectivityStatus.unavailable &&
          monitor.apiStatus != ConnectivityStatus.unavailable);
}

/// Why invitations cannot be sent, in words: the app's own reason, else the
/// server's, else `null` when they can be sent.
String? sendUnavailableText(
  AppLocalizations l10n,
  PilotInvitations invitations,
) => switch (invitations.sendUnavailable) {
  SendUnavailable.signIn => l10n.pilotCardsUnavailableSignIn,
  SendUnavailable.serverIssuesNone => l10n.pilotCardsUnavailableServer,
  SendUnavailable.linksUnreproducible => l10n.pilotCardsUnavailableLinks,
  SendUnavailable.notInThisVersion => l10n.pilotCardsUnavailableVersion,
  null => invitations.sendUnavailableReason,
};

/// Why invitations cannot be sent for this contest now, in words, or `null`
/// when they can. [unreachable] is [invitationsUnreachableText].
String? invitationsUnavailableText(
  AppLocalizations l10n,
  PilotInvitations invitations, {
  String? unreachable,
}) => !invitations.synchronized
    ? l10n.pilotCardsReminderUnsynced
    : unreachable ?? sendUnavailableText(l10n, invitations);

/// Asks to send invitations for [count] pilots. Answers whether to go on.
/// Sending is its own confirmation. It creates the QR codes and links only;
/// nobody is emailed.
Future<bool> confirmSendInvitations(BuildContext context, int count) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        key: const ValueKey('cards-send-dialog'),
        icon: const Icon(Icons.campaign),
        title: Text(l10n.pilotCardsSendTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(l10n.pilotCardsSendBody),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                const Icon(Icons.qr_code_2, size: 20),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l10n.pilotCardsQrCount(count),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(text: l10n.pilotCardsSendCountNote),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.pilotCardsCancel),
          ),
          FilledButton(
            key: const ValueKey('cards-send-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.pilotCardsSendConfirm),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

/// Confirms, then creates invitations for [participations] (those without
/// one). Never emails. Every entry point (the cards, the workspace and the
/// participants list) sends through here.
///
/// The server's reachability is checked before the confirmation and again
/// right after it, so a connection lost while the director decides says so
/// instead of failing a request. With [announce] the result is said in a snack
/// bar; the cards show it in their banners instead.
Future<bool> sendInvitationsGuarded(
  BuildContext context,
  PilotInvitationSession session,
  List<Id> participations, {
  bool announce = true,
}) async {
  if (participations.isEmpty) return false;
  if (!_reachable(context)) return false;
  if (!await confirmSendInvitations(context, participations.length)) {
    return false;
  }
  // The page may have been left, or the connection lost, while the dialog
  // was open.
  if (!context.mounted || !_reachable(context)) return false;
  final ok = await session.send(participations);
  // The send itself is finished either way; only the message needs a page.
  if (!announce || !context.mounted) return ok;
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

/// True when the server can be reached; otherwise says why in a snack bar.
bool _reachable(BuildContext context) {
  final reason = invitationsUnreachableText(
    context,
    AppLocalizations.of(context),
  );
  if (reason == null) return true;
  _say(context, reason);
  return false;
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
