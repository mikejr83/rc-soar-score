import 'dart:convert';

import 'package:aws_common/aws_common.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_server/config/support_config.dart';
import 'package:soar_score_server/mail/ses_v2_sender.dart';
import 'package:soar_score_server/mail/transactional_mail_sender.dart';
import 'package:test/test.dart';

const _credentials = AWSCredentials('AKIDEXAMPLE', 'secret-example-key');

const _message = MailMessage(
  to: ['support@rcsoarscore.com'],
  cc: ['cc@example.test'],
  bcc: ['bcc@example.test'],
  replyTo: ['pilot@example.test'],
  subject: 'Support: Online Score Entry',
  text: 'Héllo — a message',
);

Map<String, dynamic> _body(http.Request request) =>
    jsonDecode(utf8.decode(request.bodyBytes)) as Map<String, dynamic>;

void main() {
  late List<http.Request> requests;

  SesV2Sender sender({
    required http.Response Function(http.Request) respond,
    MailDeliveryMode? mode = MailDeliveryMode.live,
    AWSCredentials? credentials = _credentials,
  }) => SesV2Sender(
    client: MockClient((request) async {
      requests.add(request);
      return respond(request);
    }),
    credentials: credentials,
    mode: mode,
  );

  setUp(() => requests = []);

  test('one signed UTF-8 POST to the Ohio v2 endpoint with the intended envelope', () async {
    final outcome = await sender(
      respond: (_) => http.Response('{"MessageId":"abc"}', 200),
    ).send(_message);

    expect(outcome, isA<MailAccepted>());
    expect(requests, hasLength(1));
    final request = requests.single;
    expect(request.method, 'POST');
    expect(
      request.url.toString(),
      'https://email.us-east-2.amazonaws.com/v2/email/outbound-emails',
    );
    expect(request.headers['authorization'], startsWith('AWS4-HMAC-SHA256 '));
    expect(
      request.headers['authorization'],
      contains('/us-east-2/ses/aws4_request'),
    );

    final body = _body(request);
    expect(body['FromEmailAddress'], 'notifications@rcsoarscore.com');
    expect(body['Destination'], {
      'ToAddresses': ['support@rcsoarscore.com'],
      'CcAddresses': ['cc@example.test'],
      'BccAddresses': ['bcc@example.test'],
    });
    expect(body['ReplyToAddresses'], ['pilot@example.test']);
    expect(
      body['Content']['Simple']['Subject'],
      {'Data': 'Support: Online Score Entry', 'Charset': 'UTF-8'},
    );
    expect(
      body['Content']['Simple']['Body']['Text'],
      {'Data': 'Héllo — a message', 'Charset': 'UTF-8'},
    );
  });

  test('redirect mode sends only to the test alias with a [TEST] subject', () async {
    await sender(
      mode: MailDeliveryMode.redirect,
      respond: (_) => http.Response('{"MessageId":"abc"}', 200),
    ).send(_message);
    final body = _body(requests.single);
    expect(body['Destination'], {'ToAddresses': ['test@rcsoarscore.com']});
    expect(body['ReplyToAddresses'], ['test@rcsoarscore.com']);
    expect(
      body['Content']['Simple']['Subject']['Data'],
      '[TEST] Support: Online Score Entry',
    );
  });

  test('a 200 without a MessageId is unconfirmed', () async {
    final outcome = await sender(
      respond: (_) => http.Response('{}', 200),
    ).send(_message);
    expect(outcome, isA<MailUnconfirmed>());
  });

  test('a malformed success body is unconfirmed', () async {
    final outcome = await sender(
      respond: (_) => http.Response('<html>', 200),
    ).send(_message);
    expect(outcome, isA<MailUnconfirmed>());
  });

  test('an explicit rejection is rejected', () async {
    final outcome = await sender(
      respond: (_) => http.Response('{"__type":"MessageRejected"}', 400),
    ).send(_message);
    expect(outcome, isA<MailRejected>());
  });

  test('throttling and denied credentials are unavailable', () async {
    for (final status in [429, 403]) {
      final outcome = await sender(
        respond: (_) => http.Response('{}', status),
      ).send(_message);
      expect(outcome, isA<MailUnavailable>(), reason: 'HTTP $status');
    }
  });

  test('a server failure is unconfirmed', () async {
    final outcome = await sender(
      respond: (_) => http.Response('{}', 500),
    ).send(_message);
    expect(outcome, isA<MailUnconfirmed>());
  });

  test('a timeout is unconfirmed after exactly one provider call', () async {
    final slow = SesV2Sender(
      client: MockClient((request) async {
        requests.add(request);
        await Future<void>.delayed(const Duration(seconds: 2));
        return http.Response('{"MessageId":"late"}', 200);
      }),
      credentials: _credentials,
      mode: MailDeliveryMode.live,
      deadline: const Duration(milliseconds: 50),
    );
    expect(await slow.send(_message), isA<MailUnconfirmed>());
    expect(requests, hasLength(1));
  });

  test('headers and body share one deadline, not one each', () async {
    // Headers arrive after 60 ms and the body after another 60 ms: each part
    // is inside the 100 ms deadline, but the exchange is not.
    final slow = SesV2Sender(
      client: MockClient.streaming((request, _) async {
        requests.add(request as http.Request);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        Stream<List<int>> body() async* {
          await Future<void>.delayed(const Duration(milliseconds: 60));
          yield utf8.encode('{"MessageId":"late"}');
        }

        return http.StreamedResponse(body(), 200);
      }),
      credentials: _credentials,
      mode: MailDeliveryMode.live,
      deadline: const Duration(milliseconds: 100),
    );
    expect(await slow.send(_message), isA<MailUnconfirmed>());
  });

  test('missing credentials or mode make zero calls and are unavailable', () async {
    expect(
      await sender(
        credentials: null,
        respond: (_) => fail('no call expected'),
      ).send(_message),
      isA<MailUnavailable>(),
    );
    expect(
      await sender(
        mode: null,
        respond: (_) => fail('no call expected'),
      ).send(_message),
      isA<MailUnavailable>(),
    );
    expect(requests, isEmpty);
  });

  group('support settings', () {
    Map<String, String> env({
      String? app,
      String? mode,
      String? hosts = 'soar.example.test',
      String? turnstile = 'turnstile-secret',
      String? throttle = '0123456789abcdef0123456789abcdef',
    }) => {
      'FLY_APP_NAME': ?app,
      'MAIL_DELIVERY_MODE': ?mode,
      'SES_ACCESS_KEY_ID': 'AKID',
      'SES_SECRET_ACCESS_KEY': 'secret',
      'SUPPORT_ALLOWED_HOSTNAMES': ?hosts,
      'TURNSTILE_SECRET_KEY': ?turnstile,
      'SUPPORT_THROTTLE_SECRET': ?throttle,
    };

    test('production delivers live only with an explicit live mode', () {
      expect(
        SupportConfig.parse(env(app: productionFlyApp, mode: 'live'))?.mode,
        MailDeliveryMode.live,
      );
      expect(SupportConfig.parse(env(app: productionFlyApp)), isNull);
      expect(
        SupportConfig.parse(env(app: productionFlyApp, mode: 'redirect')),
        isNull,
      );
    });

    test('elsewhere, unset or redirect is redirect and live is disabled', () {
      expect(SupportConfig.parse(env())?.mode, MailDeliveryMode.redirect);
      expect(
        SupportConfig.parse(env(mode: 'redirect'))?.mode,
        MailDeliveryMode.redirect,
      );
      expect(SupportConfig.parse(env(mode: 'live')), isNull);
    });

    test('incomplete or invalid settings disable support', () {
      expect(SupportConfig.parse(env(hosts: null)), isNull);
      expect(
        SupportConfig.parse(env(hosts: 'https://soar.example.test')),
        isNull,
      );
      expect(SupportConfig.parse(env(turnstile: null)), isNull);
      expect(SupportConfig.parse(env(throttle: 'short')), isNull);
    });

    test('Cloudflare dummy secrets are refused in live mode only', () {
      const dummy = '1x0000000000000000000000000000000AA';
      expect(
        SupportConfig.parse(
          env(app: productionFlyApp, mode: 'live', turnstile: dummy),
        ),
        isNull,
      );
      expect(SupportConfig.parse(env(turnstile: dummy)), isNotNull);
    });
  });
}
