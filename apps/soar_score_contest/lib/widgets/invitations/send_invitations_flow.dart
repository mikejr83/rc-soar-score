import 'package:material_ui/material_ui.dart';
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

/// The pilots a send is for, by participation id, with their names for the
/// dialogs (names only: addresses stay off a shared screen).
typedef InvitationNames = Map<String, String>;

/// Asks to send invitations to [participations]. Answers whether to go on.
/// Sending is its own confirmation: it creates the links and QR codes of the
/// pilots who have none and emails every pilot with an address on file their
/// link, again for those emailed before ([emailedBefore]).
Future<bool> confirmSendInvitations(
  BuildContext context,
  List<Id> participations, {
  InvitationNames names = const {},
  int emailedBefore = 0,
}) async {
  final count = participations.length;
  final listed = [
    for (final id in participations)
      if (names[id.value] != null) names[id.value]!,
  ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        key: const ValueKey('cards-send-dialog'),
        icon: const Icon(Icons.campaign),
        title: Text(l10n.pilotCardsSendTitle),
        content: SingleChildScrollView(
          child: Column(
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
              Text(l10n.invitationsSendEmailNote),
              if (emailedBefore > 0)
                Text(
                  l10n.invitationsSendAgainNote(emailedBefore),
                  key: const ValueKey('cards-send-again-note'),
                ),
              if (listed.isNotEmpty) ...[
                Text(
                  l10n.invitationsSendNamesTitle,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  listed.join(', '),
                  key: const ValueKey('cards-send-names'),
                ),
              ],
            ],
          ),
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

/// Tells the director which pilots were not emailed and why, in names, after
/// a send. The links exist whatever happened here.
Future<void> showInvitationEmailResult(
  BuildContext context,
  InvitationEmailReport report,
  InvitationNames names, {
  List<Id> targets = const [],
}) {
  final l10n = AppLocalizations.of(context);
  // A service-wide failure answers for nobody in particular: every target
  // is a pilot whose email did not go out.
  if (report.serviceUnavailable && report.kinds.isEmpty) {
    report = InvitationEmailReport(
      kinds: {for (final id in targets) id.value: InvitationEmailKind.notSent},
      serviceUnavailable: true,
    );
  }
  String nameOf(String id) => names[id] ?? '';
  // Pilots whose name is not known are still counted, never dropped.
  List<String> namesOf(InvitationEmailKind kind) {
    final listed = <String>[];
    var unnamed = 0;
    for (final entry in report.kinds.entries) {
      if (entry.value != kind) continue;
      final name = nameOf(entry.key);
      if (name.isEmpty) {
        unnamed++;
      } else {
        listed.add(name);
      }
    }
    listed.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (unnamed > 0) listed.add(l10n.invitationsResultUnnamed(unnamed));
    return listed;
  }

  final groups = [
    (l10n.invitationsResultNotSent, namesOf(InvitationEmailKind.notSent)),
    (l10n.invitationsResultLimit, namesOf(InvitationEmailKind.limitReached)),
    (l10n.invitationsResultUnknown, namesOf(InvitationEmailKind.unknown)),
    (l10n.invitationsResultNoAddress, namesOf(InvitationEmailKind.noAddress)),
  ].where((group) => group.$2.isNotEmpty);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('invitations-result-dialog'),
      icon: const Icon(Icons.mail_outline),
      title: Text(l10n.invitationsResultTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              report.serviceUnavailable
                  ? l10n.invitationsResultServiceDown
                  : l10n.invitationsResultLead,
            ),
            for (final (title, listed) in groups) ...[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(listed.join(', ')),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          key: const ValueKey('invitations-result-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.invitationsResultClose),
        ),
      ],
    ),
  );
}

/// Confirms, then sends invitations to [participations]: links for those
/// without one, and an email with the link to every pilot who has an address.
/// Every entry point (the cards, the workspace and the participants list)
/// sends through here, so "Send again" is just sending to pilots who already
/// have links.
///
/// The server's reachability is checked before the confirmation and again
/// right after it, so a connection lost while the director decides says so
/// instead of failing a request. With [announce] the result is said in a snack
/// bar; the cards show it in their banners instead. Pilots whose email did not
/// go out are always listed in a dialog, whatever [announce] says.
Future<bool> sendInvitationsGuarded(
  BuildContext context,
  PilotInvitationSession session,
  List<Id> participations, {
  bool announce = true,
  InvitationNames names = const {},
}) async {
  if (participations.isEmpty) return false;
  if (!_reachable(context)) return false;
  final emailedBefore = [
    for (final id in participations)
      if (session.invitations.emailKindOf(id) == InvitationEmailKind.emailed)
        id,
  ].length;
  if (!await confirmSendInvitations(
    context,
    participations,
    names: names,
    emailedBefore: emailedBefore,
  )) {
    return false;
  }
  // The page may have been left, or the connection lost, while the dialog
  // was open.
  if (!context.mounted || !_reachable(context)) return false;
  final ok = await session.send(participations);
  // The send itself is finished either way; only the message needs a page.
  if (!context.mounted) return ok;
  final l10n = AppLocalizations.of(context);
  final report = session.lastEmail;
  // A send whose read-back failed still sent.
  final sent = ok || session.phase == InvitationPhase.sentNotLoaded;
  if (sent &&
      (report.serviceUnavailable ||
          report.count(InvitationEmailKind.notSent) > 0 ||
          report.count(InvitationEmailKind.limitReached) > 0 ||
          report.count(InvitationEmailKind.unknown) > 0 ||
          report.count(InvitationEmailKind.noAddress) > 0)) {
    await showInvitationEmailResult(
      context,
      report,
      names,
      targets: participations,
    );
    if (!context.mounted) return ok;
  }
  if (!announce) return ok;
  final noAddress = report.count(InvitationEmailKind.noAddress);
  final unknown = report.count(InvitationEmailKind.unknown);
  final emailed = report.count(InvitationEmailKind.emailed);
  _say(
    context,
    ok
        ? (unknown > 0
                  ? l10n.invitationsSentUnconfirmedSnack(
                      participations.length,
                      emailed,
                      unknown,
                    )
                  : l10n.invitationsSentSnack(participations.length, emailed)) +
              (noAddress > 0
                  ? l10n.invitationsSentNoAddressNote(noAddress)
                  : '')
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
