import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/reports/pilot_cards/pilot_invitations.dart';
import '../../../services/reports/report_pilot.dart';
import '../viewer/report_definition.dart';
import '../viewer/viewer_banner.dart';

/// What the director chose in the print reminder.
enum _Reminder { sendAndPrint, printWithout, cancel }

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

/// Asks to send invitations for [count] pilots. Answers whether to go on. Sending is
/// its own confirmation. It creates the QR codes and links only; nobody is
/// emailed.
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

/// The reminder before the system print dialog when some cards have no QR
/// code. It is a reminder, never a block: printing without QR codes stays
/// possible. Answers whether to go on printing.
Future<bool> remindAboutMissingQr({
  required BuildContext context,
  required PilotInvitationSession session,
  required List<ReportPilot> selected,
  required List<ReportPilot> missing,
  required bool online,
}) async {
  final l10nOuter = AppLocalizations.of(context);
  final unavailable = !session.invitations.synchronized
      ? l10nOuter.pilotCardsReminderUnsynced
      : !online
      ? l10nOuter.pilotCardsReminderOffline
      : sendUnavailableText(l10nOuter, session.invitations);
  final answer = await showDialog<_Reminder>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        key: const ValueKey('cards-reminder-dialog'),
        icon: const Icon(Icons.qr_code_2),
        title: Text(l10n.pilotCardsReminderTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              missing.length == selected.length
                  ? l10n.pilotCardsReminderNone(selected.length)
                  : l10n.pilotCardsReminderSome(
                      missing.length,
                      selected.length,
                    ),
            ),
            if (unavailable != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  const Icon(Icons.block, size: 18),
                  Expanded(
                    child: Text(
                      unavailable,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
          ],
        ),
        actionsOverflowDirection: VerticalDirection.down,
        actionsOverflowAlignment: OverflowBarAlignment.end,
        actions: [
          if (unavailable == null)
            FilledButton(
              key: const ValueKey('cards-reminder-send'),
              onPressed: () =>
                  Navigator.of(context).pop(_Reminder.sendAndPrint),
              child: Text(l10n.pilotCardsReminderSend),
            ),
          OutlinedButton(
            key: const ValueKey('cards-reminder-without'),
            onPressed: () => Navigator.of(context).pop(_Reminder.printWithout),
            child: Text(l10n.pilotCardsReminderWithout),
          ),
          TextButton(
            key: const ValueKey('cards-reminder-cancel'),
            onPressed: () => Navigator.of(context).pop(_Reminder.cancel),
            child: Text(l10n.pilotCardsCancel),
          ),
        ],
      );
    },
  );
  switch (answer) {
    case _Reminder.printWithout:
      return true;
    case _Reminder.sendAndPrint:
      if (!context.mounted ||
          !await confirmSendInvitations(context, missing.length)) {
        return false;
      }
      return session.send([for (final p in missing) p.participationId]);
    case _Reminder.cancel:
    case null:
      return false;
  }
}

/// The banners the invitations add above the cards, for the report document.
List<ReportBanner> invitationBanners({
  required AppLocalizations l10n,
  required PilotInvitationSession session,
  required List<ReportPilot> selected,
  required List<ReportPilot> missing,
  required bool online,
}) {
  final invitations = session.invitations;
  switch (session.phase) {
    case InvitationPhase.sending:
      return [
        ReportBanner(
          kind: ViewerBannerKind.neutral,
          icon: Icons.hourglass_top,
          lead: l10n.pilotCardsSendingLead,
          text: l10n.pilotCardsSendingText(missing.length),
          busy: true,
          key: const ValueKey('cards-banner-sending'),
        ),
      ];
    case InvitationPhase.failed:
      return [
        ReportBanner(
          kind: ViewerBannerKind.error,
          icon: Icons.error,
          lead: l10n.pilotCardsFailedLead,
          text: l10n.pilotCardsFailedText,
          actions: [
            ReportBannerAction(
              l10n.pilotCardsRetry,
              (context) => _send(context, session, missing),
              filled: true,
              key: const ValueKey('cards-banner-retry'),
            ),
          ],
          key: const ValueKey('cards-banner-failed'),
        ),
      ];
    case InvitationPhase.sentNotLoaded:
      return [
        ReportBanner(
          kind: ViewerBannerKind.info,
          icon: Icons.sync_problem,
          lead: l10n.pilotCardsNotLoadedLead,
          text: l10n.pilotCardsNotLoadedText,
          actions: [
            ReportBannerAction(
              l10n.pilotCardsLoadCodes,
              (_) => session.reload(),
              filled: true,
              key: const ValueKey('cards-banner-reload'),
            ),
          ],
          key: const ValueKey('cards-banner-not-loaded'),
        ),
      ];
    case InvitationPhase.sent when missing.isEmpty:
      return [
        ReportBanner(
          kind: ViewerBannerKind.official,
          icon: Icons.check_circle,
          lead: l10n.pilotCardsSentLead,
          text: l10n.pilotCardsSentText,
          actions: [
            ReportBannerAction(
              l10n.pilotCardsDismiss,
              (_) => session.dismissSent(),
              key: const ValueKey('cards-banner-dismiss'),
            ),
          ],
          key: const ValueKey('cards-banner-sent'),
        ),
      ];
    case InvitationPhase.loadFailed:
      return [
        ReportBanner(
          kind: ViewerBannerKind.error,
          icon: Icons.sync_problem,
          lead: l10n.pilotCardsLoadFailedLead,
          text: l10n.pilotCardsLoadFailedText,
          actions: [
            ReportBannerAction(
              l10n.pilotCardsRetry,
              (_) => session.reload(),
              filled: true,
              key: const ValueKey('cards-banner-load-retry'),
            ),
          ],
          key: const ValueKey('cards-banner-load-failed'),
        ),
      ];
    case InvitationPhase.idle:
    case InvitationPhase.sent:
      break;
  }
  if (missing.isEmpty || selected.isEmpty) {
    return const [];
  }
  if (!invitations.synchronized) {
    return [
      ReportBanner(
        kind: ViewerBannerKind.neutral,
        icon: Icons.cloud_off,
        lead: l10n.pilotCardsUnsyncedLead,
        text: l10n.pilotCardsUnsyncedText,
        key: const ValueKey('cards-banner-unsynced'),
      ),
    ];
  }
  if (!online) {
    return [
      ReportBanner(
        kind: ViewerBannerKind.neutral,
        icon: Icons.cloud_off,
        lead: l10n.pilotCardsOfflineLead,
        text: l10n.pilotCardsOfflineText,
        key: const ValueKey('cards-banner-offline'),
      ),
    ];
  }
  final reason = sendUnavailableText(l10n, invitations);
  final what = missing.length == selected.length
      ? l10n.pilotCardsMissingAll
      : l10n.pilotCardsMissingCount(missing.length);
  return [
    ReportBanner(
      kind: ViewerBannerKind.neutral,
      icon: Icons.qr_code_2,
      lead: l10n.pilotCardsMissingLead,
      text: reason == null
          ? what
          : '$what ${l10n.pilotCardsMissingReason(reason)}',
      actions: [
        ReportBannerAction(
          l10n.pilotCardsSendAction,
          reason == null ? (context) => _send(context, session, missing) : null,
          filled: true,
          key: const ValueKey('cards-banner-send'),
        ),
      ],
      key: const ValueKey('cards-banner-missing'),
    ),
  ];
}

Future<void> _send(
  BuildContext context,
  PilotInvitationSession session,
  List<ReportPilot> missing,
) async {
  if (await confirmSendInvitations(context, missing.length)) {
    await session.send([for (final p in missing) p.participationId]);
  }
}
