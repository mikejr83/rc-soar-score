import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_server/mail/invitation_mailer.dart';
import 'package:soar_score_server/mail/transactional_mail_sender.dart';
import 'package:test/test.dart';

class _Sender implements TransactionalMailSender {
  _Sender(this.outcome);
  final MailOutcome outcome;
  MailMessage? last;

  @override
  Future<MailOutcome> send(MailMessage message) async {
    last = message;
    return outcome;
  }
}

InvitationMail _mail() => InvitationMail(
  to: 'alex@example.com',
  pilotName: 'Alex Rivera',
  contestName: 'Spring Open',
  contestStart: DateTime.utc(2026, 10, 17, 14),
  contestEnd: DateTime.utc(2026, 10, 19, 3),
  timeZone: 'America/Denver',
  location: const ['Front Range Soaring', 'Denver', 'CO'],
  link: 'https://score.rcsoarscore.com/invitations/abc',
);

void main() {
  test('writes the link and the contest in the contest\'s own zone', () {
    final text = invitationMailText(_mail());
    expect(text, contains('Hello Alex Rivera,'));
    expect(text, contains('Spring Open (Front Range Soaring, Denver, CO)'));
    // 03:00 UTC on the 19th is still the 18th in Denver.
    expect(text, contains('2026-10-17 to 2026-10-18'));
    expect(text, contains('https://score.rcsoarscore.com/invitations/abc'));
    expect(text, contains('Replies to this address are not read'));
  });

  test('sends to the pilot with no Reply-To', () async {
    final sender = _Sender(const MailAccepted('id-1'));
    final result = await SesInvitationMailer(sender).send(_mail());
    expect(sender.last!.to, ['alex@example.com']);
    expect(sender.last!.replyTo, isEmpty);
    expect(sender.last!.subject, contains('Spring Open'));
    expect(result.status, InvitationEmailStatus.accepted);
    expect(result.messageId, 'id-1');
  });

  test('maps every sender outcome', () async {
    for (final (outcome, status) in [
      (const MailRejected(), InvitationEmailStatus.rejected),
      (const MailUnavailable(), InvitationEmailStatus.unavailable),
      (const MailUnconfirmed(), InvitationEmailStatus.unconfirmed),
    ]) {
      final result = await SesInvitationMailer(_Sender(outcome)).send(_mail());
      expect(result.status, status);
      expect(result.messageId, isNull);
    }
  });
}
