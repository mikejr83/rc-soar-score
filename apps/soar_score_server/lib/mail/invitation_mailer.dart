import 'package:intl/intl.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'email_template.dart';
import 'transactional_mail_sender.dart';

/// Sends invitation emails (#790) through the shared transactional sender.
///
/// The message has no Reply-To: it comes from the notifications address and
/// says that replies are not read. It carries an HTML part and a plain-text
/// part, both with the pilot's secret link, so nothing here logs it.
class SesInvitationMailer implements InvitationMailer {
  SesInvitationMailer(this._sender, this._templates);

  final TransactionalMailSender _sender;
  final InvitationTemplates _templates;

  @override
  Future<InvitationMailResult> send(InvitationMail mail) async {
    final outcome = await _sender.send(
      MailMessage(
        to: [mail.to],
        replyTo: const [],
        subject: 'Your scoring link for ${mail.contestName}',
        text: invitationMailText(mail, _templates),
        html: invitationMailHtml(mail, _templates),
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

/// The hosted logo the HTML part shows (480 x 118 px, the same in every
/// email).
const invitationLogoUrl =
    'https://rcsoarscore.com/brand/rc-soar-score-lockup-dark-compact-480.png';

/// The plain text of an invitation email.
String invitationMailText(InvitationMail mail, InvitationTemplates templates) =>
    templates.text.fill(_values(mail));

/// The HTML of an invitation email; every value is escaped.
String invitationMailHtml(InvitationMail mail, InvitationTemplates templates) =>
    templates.html.fill(_values(mail), escape: escapeHtml);

Map<String, String> _values(InvitationMail mail) {
  final dates = invitationDateLine(mail);
  return {
    'contestName': mail.contestName.trim(),
    'pilotName': mail.pilotName.trim(),
    'locationLine': mail.location.isEmpty
        ? ''
        : ' (${mail.location.join(', ')})',
    'dateLine': dates == null ? '' : ', $dates',
    'link': mail.link,
    'logoUrl': invitationLogoUrl,
  };
}

/// The contest's first and last day in its own zone, in the pilot's locale:
/// `Sat, Oct 10, 2026`, `Oct 10 to Oct 11, 2026` or
/// `Oct 30 to Nov 1, 2026`.
///
/// Needs the locale's date symbols loaded (`initializeDateFormatting`) when it
/// is not `en-US`. The word "to" is English until the emails are translated.
String? invitationDateLine(InvitationMail mail) {
  final tag = Intl.canonicalizedLocale(mail.locale);
  final start = ContestTime.inZone(mail.contestStart, mail.timeZone);
  final end = ContestTime.inZone(mail.contestEnd, mail.timeZone);
  if (start.year == end.year &&
      start.month == end.month &&
      start.day == end.day) {
    return DateFormat.yMMMEd(tag).format(start);
  }
  final first = start.year == end.year
      ? DateFormat.MMMd(tag).format(start)
      : DateFormat.yMMMd(tag).format(start);
  return '$first to ${DateFormat.yMMMd(tag).format(end)}';
}
