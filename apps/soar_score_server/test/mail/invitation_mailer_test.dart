import 'dart:io';

import 'package:intl/date_symbol_data_local.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_server/mail/email_template.dart';
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

const _link = 'https://score.rcsoarscore.com/invitations/abc';

InvitationMail _mail({
  String pilotName = 'Alex Rivera',
  String contestName = 'Spring Open',
  DateTime? end,
  List<String> location = const ['Front Range Soaring', 'Denver', 'CO'],
}) => InvitationMail(
  to: 'alex@example.com',
  pilotName: pilotName,
  contestName: contestName,
  contestStart: DateTime.utc(2026, 10, 17, 14),
  contestEnd: end ?? DateTime.utc(2026, 10, 19, 3),
  timeZone: 'America/Denver',
  location: location,
  link: _link,
);

void main() {
  late InvitationTemplates templates;

  setUpAll(() async {
    await initializeDateFormatting();
    templates = await InvitationTemplates.load(Directory('email'));
  });

  group('plain text', () {
    test('writes the link and the contest in the contest\'s own zone', () {
      final text = invitationMailText(_mail(), templates);
      expect(text, contains('Hello Alex Rivera,'));
      expect(text, contains('Spring Open (Front Range Soaring, Denver, CO), '));
      // 03:00 UTC on the 19th is still the 18th in Denver.
      expect(text, contains('Oct 17 to Oct 18, 2026.'));
      expect(text, contains(_link));
      expect(text, contains('This link is yours alone'));
      expect(text, contains('Replies to this address are not read'));
      expect(text, isNot(contains('{{')));
    });

    test('is not HTML-escaped', () {
      final text = invitationMailText(
        _mail(contestName: 'F3J & F5J "Open"'),
        templates,
      );
      expect(text, contains('F3J & F5J "Open"'));
      expect(text, isNot(contains('&amp;')));
    });

    test('an empty name reads Hello,', () {
      expect(
        invitationMailText(_mail(pilotName: '  '), templates),
        contains('\nHello,\n'),
      );
    });

    test('has no brackets without a location', () {
      expect(
        invitationMailText(_mail(location: const []), templates),
        contains('You are entered in Spring Open, Oct 17'),
      );
    });
  });

  group('HTML', () {
    test('fills every placeholder and shows the hosted logo', () {
      final html = invitationMailHtml(_mail(), templates);
      expect(html, isNot(contains('{{')));
      expect(html, contains(invitationLogoUrl));
      expect(html, contains('Hello Alex Rivera,'));
      expect(
        html,
        contains('<title>Your scoring link for Spring Open</title>'),
      );
    });

    test('escapes every value', () {
      final html = invitationMailHtml(
        _mail(
          contestName: 'F3J & F5J <Open> "2026"',
          pilotName: '<script>x</script>',
          location: const ["Dave's Field"],
        ),
        templates,
      );
      expect(html, contains('F3J &amp; F5J &lt;Open&gt; &quot;2026&quot;'));
      expect(html, isNot(contains('<script>')));
      expect(html, contains('Dave&#39;s Field'));
    });

    test('the link appears only where the template puts it', () {
      final html = invitationMailHtml(_mail(), templates);
      // VML button, HTML button, fallback text.
      expect(_link.allMatches(html).length, 3);
    });

    test('an empty name reads Hello,', () {
      expect(
        invitationMailHtml(_mail(pilotName: ''), templates),
        contains('>Hello,</td>'),
      );
    });
  });

  group('dates', () {
    test('one day carries its weekday', () {
      expect(
        invitationDateLine(_mail(end: DateTime.utc(2026, 10, 17, 20))),
        'Sat, Oct 17, 2026',
      );
    });

    test('a span across months and years', () {
      expect(
        invitationDateLine(_mail(end: DateTime.utc(2026, 11, 2, 20))),
        'Oct 17 to Nov 2, 2026',
      );
      expect(
        invitationDateLine(_mail(end: DateTime.utc(2027, 1, 2, 20))),
        'Oct 17, 2026 to Jan 2, 2027',
      );
    });
  });

  test('sends HTML and text to the pilot with no Reply-To', () async {
    final sender = _Sender(const MailAccepted('id-1'));
    final result = await SesInvitationMailer(sender, templates).send(_mail());
    expect(sender.last!.to, ['alex@example.com']);
    expect(sender.last!.replyTo, isEmpty);
    expect(sender.last!.subject, 'Your scoring link for Spring Open');
    expect(sender.last!.text, contains(_link));
    expect(sender.last!.html, contains('<!DOCTYPE html>'));
    expect(result.status, InvitationEmailStatus.accepted);
    expect(result.messageId, 'id-1');
  });

  test('maps every sender outcome', () async {
    for (final (outcome, status) in [
      (const MailRejected(), InvitationEmailStatus.rejected),
      (const MailUnavailable(), InvitationEmailStatus.unavailable),
      (const MailUnconfirmed(), InvitationEmailStatus.unconfirmed),
    ]) {
      final result = await SesInvitationMailer(
        _Sender(outcome),
        templates,
      ).send(_mail());
      expect(result.status, status);
      expect(result.messageId, isNull);
    }
  });
}
