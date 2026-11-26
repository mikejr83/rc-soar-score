import 'package:soar_score_core/soar_score_core.dart';

import 'transactional_mail_sender.dart';

/// Sends invitation emails (#790) through the shared transactional sender.
///
/// The message has no Reply-To: it comes from the notifications address and
/// says that replies are not read. The text carries the pilot's secret link,
/// so nothing here logs it.
class SesInvitationMailer implements InvitationMailer {
  SesInvitationMailer(this._sender);

  final TransactionalMailSender _sender;

  @override
  Future<InvitationMailResult> send(InvitationMail mail) async {
    final outcome = await _sender.send(
      MailMessage(
        to: [mail.to],
        replyTo: const [],
        subject: 'Your scoring link for ${mail.contestName}',
        text: invitationMailText(mail),
      ),
    );
    return switch (outcome) {
      MailAccepted(:final messageId) => InvitationMailResult(
        InvitationEmailStatus.accepted,
        messageId: messageId,
      ),
      MailRejected() => const InvitationMailResult(
        InvitationEmailStatus.rejected,
      ),
      MailUnavailable() => const InvitationMailResult(
        InvitationEmailStatus.unavailable,
      ),
      MailUnconfirmed() => const InvitationMailResult(
        InvitationEmailStatus.unconfirmed,
      ),
    };
  }
}

/// The plain text of an invitation email.
String invitationMailText(InvitationMail mail) {
  final when = _dates(mail);
  return [
    'Hello ${mail.pilotName},',
    '',
    'You are entered in ${mail.contestName}'
        '${mail.location.isEmpty ? '' : ' (${mail.location.join(', ')})'}'
        '${when == null ? '' : ', $when'}.',
    '',
    'Use this personal link to enter and review your scores:',
    '',
    mail.link,
    '',
    'The link is yours alone, so please do not share it. It stops working '
        '24 hours after the contest is completed.',
    '',
    'Your contest director sent this invitation. Replies to this address '
        'are not read; please contact the director with any questions.',
    '',
  ].join('\n');
}

/// The contest's first and last day in its own zone, as `2026-10-08`.
String? _dates(InvitationMail mail) {
  String day(DateTime utc) {
    final t = ContestTime.inZone(utc, mail.timeZone);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}';
  }

  final start = day(mail.contestStart);
  final end = day(mail.contestEnd);
  return start == end ? start : '$start to $end';
}
