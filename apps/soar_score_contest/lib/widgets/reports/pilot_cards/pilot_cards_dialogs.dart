import 'package:flutter/material.dart';

import '../../../services/reports/pilot_cards/pilot_invitations.dart';
import '../../../services/reports/report_pilot.dart';
import '../viewer/report_definition.dart';
import '../viewer/viewer_banner.dart';

/// What the director chose in the print reminder.
enum _Reminder { sendAndPrint, printWithout, cancel }

/// Plural helper for the dialogs' counts.
String _count(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

/// Asks to send invitations to [pilots]. Answers whether to go on. Sending is
/// its own confirmation because it emails people and cannot be taken back.
Future<bool> confirmSendInvitations(
  BuildContext context,
  List<ReportPilot> pilots,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('cards-send-dialog'),
      icon: const Icon(Icons.campaign),
      title: const Text('Send invitations?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const Text(
            'Invitations will be sent to participants, and each of these '
            'cards will carry a QR code.',
          ),
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
                        text: _count(pilots.length, 'QR code'),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(
                        text:
                            ' — one per pilot, the same on every reprint. '
                            'Pilots with an email address are also emailed '
                            'their link.',
                      ),
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('cards-send-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Send invitations'),
        ),
      ],
    ),
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
  final unavailable = !session.invitations.synchronized
      ? 'This contest hasn’t synchronized, so QR codes can’t be made yet.'
      : !online
      ? 'You’re offline, so invitations can’t be sent now. QR codes already '
            'issued still print.'
      : session.invitations.sendUnavailableReason;
  final answer = await showDialog<_Reminder>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('cards-reminder-dialog'),
      icon: const Icon(Icons.qr_code_2),
      title: const Text('Some cards will print without QR codes.'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            '${missing.length == selected.length ? 'None of these ${_count(selected.length, 'card')}' : '${missing.length} of ${_count(selected.length, 'card')}'} '
            '${missing.length == 1 && selected.length == 1 ? 'has' : 'have'} a '
            'QR code yet. Pilots without one can’t scan to enter scores.',
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
            onPressed: () => Navigator.of(context).pop(_Reminder.sendAndPrint),
            child: const Text('Send invitations and print'),
          ),
        OutlinedButton(
          key: const ValueKey('cards-reminder-without'),
          onPressed: () => Navigator.of(context).pop(_Reminder.printWithout),
          child: const Text('Print without QR codes'),
        ),
        TextButton(
          key: const ValueKey('cards-reminder-cancel'),
          onPressed: () => Navigator.of(context).pop(_Reminder.cancel),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
  switch (answer) {
    case _Reminder.printWithout:
      return true;
    case _Reminder.sendAndPrint:
      if (!context.mounted || !await confirmSendInvitations(context, missing)) {
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
          lead: 'Sending invitations.',
          text:
              'Issuing ${_count(missing.length, 'QR code')}. Print is paused '
              'until the codes are ready; you can keep changing options.',
          busy: true,
          key: const ValueKey('cards-banner-sending'),
        ),
      ];
    case InvitationPhase.failed:
      return [
        ReportBanner(
          kind: ViewerBannerKind.error,
          icon: Icons.error,
          lead: 'Invitations could not be sent.',
          text:
              'No QR codes were added and nothing was sent. Check the '
              'connection and try again, or print without QR codes.',
          actions: [
            ReportBannerAction(
              'Retry',
              (context) => _send(context, session, missing),
              filled: true,
              key: const ValueKey('cards-banner-retry'),
            ),
          ],
          key: const ValueKey('cards-banner-failed'),
        ),
      ];
    case InvitationPhase.sent when missing.isEmpty:
      return [
        ReportBanner(
          kind: ViewerBannerKind.official,
          icon: Icons.check_circle,
          lead: 'Invitations sent.',
          text: 'QR codes added.',
          actions: [
            ReportBannerAction(
              'Dismiss',
              (_) => session.dismissSent(),
              key: const ValueKey('cards-banner-dismiss'),
            ),
          ],
          key: const ValueKey('cards-banner-sent'),
        ),
      ];
    case InvitationPhase.idle:
    case InvitationPhase.sent:
      break;
  }
  if (missing.isEmpty || selected.isEmpty) {
    return const [];
  }
  final some = missing.length == selected.length
      ? 'Some cards have'
      : missing.length == 1
      ? '1 card has'
      : '${missing.length} cards have';
  if (!invitations.synchronized) {
    return const [
      ReportBanner(
        kind: ViewerBannerKind.neutral,
        icon: Icons.cloud_off,
        lead: 'No QR codes yet.',
        text:
            'This contest was organized offline and hasn’t synchronized. '
            'Sync it first to create QR codes. Cards print without them.',
        key: ValueKey('cards-banner-unsynced'),
      ),
    ];
  }
  if (!online) {
    return const [
      ReportBanner(
        kind: ViewerBannerKind.neutral,
        icon: Icons.cloud_off,
        lead: 'Offline.',
        text:
            'Connect to send invitations. QR codes already issued still print.',
        key: ValueKey('cards-banner-offline'),
      ),
    ];
  }
  final reason = invitations.sendUnavailableReason;
  return [
    ReportBanner(
      kind: ViewerBannerKind.neutral,
      icon: Icons.qr_code_2,
      lead: 'No QR code.',
      text:
          '$some no QR code. Send invitations to add them.'
          '${reason == null ? '' : ' $reason You can still print without QR codes.'}',
      actions: [
        ReportBannerAction(
          'Send invitations',
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
  if (await confirmSendInvitations(context, missing)) {
    await session.send([for (final p in missing) p.participationId]);
  }
}
