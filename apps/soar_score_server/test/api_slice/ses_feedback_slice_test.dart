import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:soar_score_server/mail/ses_feedback/ses_feedback_handler.dart';
import 'package:soar_score_server/mail/ses_feedback/sns_verifier.dart';
import 'package:test/test.dart';

import '../mail/ses_feedback/sns_test_signing.dart';
import 'slice_client.dart';

const _contestId = '019c0000-0000-7000-8000-000000000020';
const _profile = '019c0000-0000-7000-8000-000000000101';
const _participation = '019c0000-0000-7000-8000-000000000201';
const _secret = 'a-test-secret-that-is-at-least-32-bytes-long';
const _address = 'alex.rivera@example.com';
const _messageId = '0100019a-4b6c-7000-aaaa-000000000001-000000';

class _FakeMailer implements core.InvitationMailer {
  @override
  Future<core.InvitationMailResult> send(core.InvitationMail mail) async =>
      const core.InvitationMailResult(
        core.InvitationEmailStatus.accepted,
        messageId: _messageId,
      );
}

/// `POST /webhooks/ses-feedback` over a real database: a genuine SES report
/// changes the stored outcome of the invitation email it is about, once, and
/// nothing else.
void main() {
  final postgresMissing = PostgresConfig.fromEnvironment() == null;
  for (final backend in SliceBackend.values) {
    group(
      backend.name,
      () => _tests(backend),
      skip: backend == SliceBackend.postgres && postgresMissing
          ? 'no PostgreSQL instance configured (set DATABASE_URL or POSTGRES_PASSWORD)'
          : false,
    );
  }
}

void _tests(SliceBackend backend) {
  late SliceClient api;
  late Handler handler;
  late List<Uri> confirmed;
  var certificateDown = false;
  var confirmationStatus = 200;
  late List<LogRecord> logs;
  late StreamSubscription<LogRecord> logSubscription;

  Handler build({bool configured = true}) {
    final upstream = MockClient((request) async {
      if (request.url.path.endsWith('.pem')) {
        return certificateDown
            ? http.Response('down', 503)
            : http.Response(testSigningCertPem, 200);
      }
      confirmed.add(request.url);
      return http.Response(
        '<ConfirmSubscriptionResponse/>',
        confirmationStatus,
      );
    });
    return createServerHandler(
      api.database,
      authMiddleware: fixedPrincipal(Principal(accountId: api.director)),
      invitationSecret: _secret,
      invitationMailer: _FakeMailer(),
      sesFeedbackHandler: configured
          ? (feedback) => sesFeedbackHandler(
              verifier: SnsVerifier(
                topic: SnsTopic.parse(testTopicArn)!,
                client: upstream,
              ),
              feedback: feedback,
              client: upstream,
            )
          : null,
    );
  }

  Future<Response> post(Object body, {String method = 'POST'}) async => handler(
    Request(
      method,
      Uri.parse('http://localhost/webhooks/ses-feedback'),
      body: body is String ? body : jsonEncode(body),
      headers: const {'content-type': 'text/plain; charset=UTF-8'},
    ),
  );

  Future<Response> report(
    String type,
    String messageId, {
    String bounceType = 'Permanent',
    String field = 'notificationType',
  }) async => post(
    signedSnsMessage(
      message: sesNotification(
        type,
        messageId,
        bounceType: bounceType,
        field: field,
      ),
    ),
  );

  Future<Map<String, Object?>> outcome() async {
    final stored = await Repository(api.database).invitationRepository
        .listForParticipation(core.Id.parse(_participation));
    return stored.single.deliveryOutcomes.single;
  }

  Future<void> call(String method, String path, Object body, int status) async {
    final response = await handler(
      Request(
        method,
        Uri.parse('http://localhost/api/v1$path'),
        body: jsonEncode(body),
      ),
    );
    expect(response.statusCode, status, reason: await response.readAsString());
  }

  setUp(() async {
    confirmed = [];
    certificateDown = false;
    confirmationStatus = 200;
    logs = [];
    Logger.root.level = Level.ALL;
    logSubscription = Logger.root.onRecord.listen(logs.add);
    api = await SliceClient.open(backend);
    handler = build();
    await api.expectOk(
      'POST',
      '/contests',
      status: 201,
      body: {
        'id': _contestId,
        'name': 'Spring Open',
        'start_date_time': '2026-10-17T14:00:00.000Z',
        'end_date_time': '2026-10-18T22:00:00.000Z',
        'timezone': 'America/Denver',
      },
    );
    await api.expectOk(
      'POST',
      '/contests/$_contestId/configuration',
      status: 201,
      body: {
        'base_revision_number': 0,
        'discipline_profile_id': core.SystemDisciplineProfiles.f5jId.value,
        'config': {
          'core': <String, Object?>{},
          'discipline': {'working_time': 600},
        },
      },
    );
    await api.expectOk(
      'POST',
      '/participants',
      status: 201,
      body: {
        'id': _profile,
        'first_name': 'Alex',
        'last_name': 'Rivera',
        'email': _address,
      },
    );
    await api.expectOk(
      'POST',
      '/contests/$_contestId/participations',
      status: 201,
      body: {
        'id': _participation,
        'participant_profile_id': _profile,
        'role_id': core.SystemRoles.pilotId.value,
      },
    );
    await call('POST', '/contests/$_contestId/invitations', {
      'request_id': 'issue-1',
      'participation_ids': [_participation],
    }, 200);
    await call('POST', '/contests/$_contestId/invitations/email', {
      'request_id': 'send-1',
      'participation_ids': [_participation],
    }, 200);
  });
  tearDown(() async {
    await logSubscription.cancel();
    await api.close();
  });

  test('a bounce marks the email bounced and the link keeps working', () async {
    final linkBefore = await _link(call: handler, contest: _contestId);
    final response = await report('Bounce', _messageId);
    expect(response.statusCode, 200);

    final stored = await outcome();
    expect(stored['status'], 'bounced');
    expect(stored['bounce_type'], 'permanent');
    expect(stored['reported_at'], isA<String>());
    expect(stored['request_id'], 'send-1');
    expect(stored['message_id'], _messageId);

    final listing = await _listing(handler, _contestId);
    expect(listing['email_status'], 'bounced');
    expect(listing['link'], linkBefore);
  });

  test(
    'bounce types are kept, and a configuration-set event is read',
    () async {
      await report(
        'Bounce',
        _messageId,
        bounceType: 'Transient',
        field: 'eventType',
      );
      expect((await outcome())['bounce_type'], 'transient');
    },
  );

  test('a complaint marks the email complained', () async {
    expect((await report('Complaint', _messageId)).statusCode, 200);
    expect((await outcome())['status'], 'complained');
  });

  test('a repeated report changes nothing', () async {
    await report('Bounce', _messageId);
    final first = await outcome();
    final response = await report('Bounce', _messageId);
    expect(response.statusCode, 200);
    expect(await outcome(), first);
  });

  test('a complaint replaces a bounce, and a bounce never replaces a '
      'complaint', () async {
    await report('Bounce', _messageId);
    await report('Complaint', _messageId);
    expect((await outcome())['status'], 'complained');
    await report('Bounce', _messageId);
    expect((await outcome())['status'], 'complained');
  });

  test('delivery events and reports about other mail change nothing', () async {
    final before = await outcome();
    for (final body in [
      sesNotification('Delivery', _messageId),
      sesNotification('Bounce', '0100019a-4b6c-7000-bbbb-000000000002-000000'),
      sesNotification('Bounce', '%'),
      sesNotification('Bounce', "x' OR '1'='1"),
      'not json',
      '[]',
      '{"mail":{}}',
    ]) {
      final response = await post(signedSnsMessage(message: body));
      expect(response.statusCode, 200, reason: body);
    }
    expect(await outcome(), before);
  });

  test('refuses what is not a genuine message from the topic', () async {
    final good = signedSnsMessage(
      message: sesNotification('Bounce', _messageId),
    );
    final forged = {
      ...good,
      'Message': sesNotification('Complaint', _messageId),
    };
    final otherTopic = signedSnsMessage(
      topicArn: 'arn:aws:sns:us-east-2:999999999999:other',
      message: sesNotification('Bounce', _messageId),
    );
    final badCert = signedSnsMessage(
      certUrl: 'https://evil.example/cert.pem',
      message: sesNotification('Bounce', _messageId),
    );
    for (final (name, body, status) in [
      ('forged text', forged, 403),
      ('other topic', otherTopic, 403),
      ('other cert host', badCert, 403),
      ('not SNS', {'Message': 'hi'}, 400),
      ('plain text', 'hello', 400),
    ]) {
      final response = await post(body);
      expect(response.statusCode, status, reason: name);
    }
    expect((await outcome())['status'], 'accepted');
  });

  test(
    'asks SNS to try again when the certificate cannot be fetched',
    () async {
      certificateDown = true;
      final response = await report('Bounce', _messageId);
      expect(response.statusCode, 503);
      expect((await outcome())['status'], 'accepted');

      certificateDown = false;
      expect((await report('Bounce', _messageId)).statusCode, 200);
      expect((await outcome())['status'], 'bounced');
    },
  );

  test('asks SNS to try again when a confirmation fails', () async {
    confirmationStatus = 500;
    final message = signedSnsMessage(type: 'SubscriptionConfirmation');
    expect((await post(message)).statusCode, 503);

    confirmationStatus = 200;
    expect((await post(message)).statusCode, 200);
  });

  test('holds a report that overtakes the send it is about', () async {
    // A second send is in flight: its entry is stored before the send, its
    // message id only after SES answers.
    final invitations = Repository(api.database).invitationRepository;
    final id = (await invitations.listForParticipation(
      core.Id.parse(_participation),
    )).single.id;
    const late = '0100019a-4b6c-7000-cccc-000000000003-000000';
    await invitations.updateDeliveryOutcomes(
      id,
      (current) => [
        ...current,
        {
          'request_id': 'send-2',
          'channel': 'email',
          'status': 'sending',
          'at': DateTime.now().toUtc().toIso8601String(),
        },
      ],
    );

    // The report arrives first: not lost, SNS is asked to deliver it again.
    expect((await report('Bounce', late)).statusCode, 503);

    // The answer is stored; the redelivered report is recorded.
    await invitations.updateDeliveryOutcomes(
      id,
      (current) => [
        for (final entry in current)
          if (entry['request_id'] == 'send-2')
            {...entry, 'status': 'accepted', 'message_id': late}
          else
            entry,
      ],
    );
    expect((await report('Bounce', late)).statusCode, 200);
    final stored = (await invitations.findById(id))!.deliveryOutcomes;
    expect(stored.last['status'], 'bounced');
    expect(stored.first['status'], 'accepted');
  });

  test('does not hold reports for a send that stopped long ago', () async {
    final invitations = Repository(api.database).invitationRepository;
    final id = (await invitations.listForParticipation(
      core.Id.parse(_participation),
    )).single.id;
    await invitations.updateDeliveryOutcomes(
      id,
      (current) => [
        ...current,
        {
          'request_id': 'send-2',
          'channel': 'email',
          'status': 'sending',
          'at': DateTime.now()
              .toUtc()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
        },
      ],
    );
    final response = await report(
      'Bounce',
      '0100019a-4b6c-7000-dddd-000000000004-000000',
    );
    expect(response.statusCode, 200);
  });

  test(
    'a report for unrelated mail is acknowledged when no send is open',
    () async {
      final response = await report(
        'Bounce',
        '0100019a-4b6c-7000-eeee-000000000005-000000',
      );
      expect(response.statusCode, 200);
    },
  );

  test('refuses a body that is too large and other methods', () async {
    expect((await post('x' * (300 * 1024))).statusCode, 413);
    expect((await post('{}', method: 'GET')).statusCode, 405);
  });

  test('answers 503 until a topic is configured', () async {
    handler = build(configured: false);
    final response = await report('Bounce', _messageId);
    expect(response.statusCode, 503);
    expect((await outcome())['status'], 'accepted');
  });

  test(
    'confirms a subscription from the topic, only at its SNS host',
    () async {
      final response = await post(
        signedSnsMessage(type: 'SubscriptionConfirmation'),
      );
      expect(response.statusCode, 200);
      expect(confirmed, [Uri.parse(testSubscribeUrl)]);

      confirmed.clear();
      final elsewhere = await post(
        signedSnsMessage(
          type: 'SubscriptionConfirmation',
          subscribeUrl: 'https://evil.example/confirm',
        ),
      );
      expect(elsewhere.statusCode, 200);
      expect(confirmed, isEmpty);
    },
  );

  test('logs record neither ids, addresses nor links', () async {
    final link = await _link(call: handler, contest: _contestId) as String;
    logs.clear();
    await report('Bounce', _messageId);
    final text = logs.map((r) => '${r.loggerName} ${r.message}').join('\n');
    expect(text, contains('reported as bounce'));
    expect(text, isNot(contains(_messageId)));
    expect(text, isNot(contains(_address)));
    expect(text, isNot(contains(link)));
    expect(text, isNot(contains(link.split('/').last)));
  });
}

Future<Map<String, Object?>> _listing(Handler handler, String contest) async {
  final response = await handler(
    Request(
      'GET',
      Uri.parse('http://localhost/api/v1/contests/$contest/invitations'),
    ),
  );
  final body =
      jsonDecode(await response.readAsString()) as Map<String, Object?>;
  return (body['invitations'] as List).cast<Map<String, Object?>>().single;
}

Future<Object?> _link({required Handler call, required String contest}) async =>
    (await _listing(call, contest))['link'];
