import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

import 'slice_client.dart';

const _contestId = '019c0000-0000-7000-8000-000000000020';
const _withEmailProfile = '019c0000-0000-7000-8000-000000000101';
const _withEmailPart = '019c0000-0000-7000-8000-000000000201';
const _noEmailProfile = '019c0000-0000-7000-8000-000000000102';
const _noEmailPart = '019c0000-0000-7000-8000-000000000202';
const _secret = 'a-test-secret-that-is-at-least-32-bytes-long';
const _address = 'alex.rivera@example.com';

/// A mailer that records what it was asked to send and answers as told.
class _FakeMailer implements core.InvitationMailer {
  final sent = <core.InvitationMail>[];
  core.InvitationMailResult result = const core.InvitationMailResult(
    core.InvitationEmailStatus.accepted,
    messageId: 'msg-1',
  );
  Object? failure;

  @override
  Future<core.InvitationMailResult> send(core.InvitationMail mail) async {
    sent.add(mail);
    if (failure != null) throw failure!;
    return result;
  }
}

/// `POST /contests/{id}/invitations/email` over a real database: the link is
/// always there, delivery is recorded per participation, and a repeated
/// request id never sends twice.
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
  late _FakeMailer mailer;
  late Handler handler;

  Handler build({bool withMailer = true}) => createServerHandler(
    api.database,
    authMiddleware: fixedPrincipal(Principal(accountId: api.director)),
    invitationSecret: _secret,
    invitationMailer: withMailer ? mailer : null,
  );

  Future<(int, Map<String, Object?>)> call(
    String method,
    String path, [
    Object? body,
  ]) async {
    final response = await handler(
      Request(
        method,
        Uri.parse('http://localhost/api/v1$path'),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    final text = await response.readAsString();
    return (
      response.statusCode,
      text.isEmpty
          ? <String, Object?>{}
          : jsonDecode(text) as Map<String, Object?>,
    );
  }

  Future<(int, Map<String, Object?>)> email(
    String requestId,
    List<String> participations,
  ) => call('POST', '/contests/$_contestId/invitations/email', {
    'request_id': requestId,
    'participation_ids': participations,
  });

  Future<Map<String, Object?>> listing() async {
    final (status, body) = await call(
      'GET',
      '/contests/$_contestId/invitations',
    );
    expect(status, 200);
    return body;
  }

  Map<String, Object?> resultFor(Map<String, Object?> body, String id) =>
      (body['results'] as List).cast<Map<String, Object?>>().singleWhere(
        (r) => r['participation_id'] == id,
      );

  setUp(() async {
    api = await SliceClient.open(backend);
    mailer = _FakeMailer();
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
    for (final (profile, participation, first, mail) in [
      (_withEmailProfile, _withEmailPart, 'Alex', _address),
      (_noEmailProfile, _noEmailPart, 'Blake', null),
    ]) {
      await api.expectOk(
        'POST',
        '/participants',
        status: 201,
        body: {
          'id': profile,
          'first_name': first,
          'last_name': 'Rivera',
          'email': ?mail,
        },
      );
      await api.expectOk(
        'POST',
        '/contests/$_contestId/participations',
        status: 201,
        body: {
          'id': participation,
          'participant_profile_id': profile,
          'role_id': core.SystemRoles.pilotId.value,
        },
      );
    }
    final (status, _) = await call(
      'POST',
      '/contests/$_contestId/invitations',
      {
        'request_id': 'issue-1',
        'participation_ids': [_withEmailPart, _noEmailPart],
      },
    );
    expect(status, 200);
  });
  tearDown(() => api.close());

  test('emails the pilot the link the director copies, and skips a pilot '
      'with no address', () async {
    final (status, body) = await email('send-1', [
      _withEmailPart,
      _noEmailPart,
    ]);
    expect(status, 200);
    expect(resultFor(body, _withEmailPart)['status'], 'accepted');
    expect(resultFor(body, _noEmailPart)['skipped'], 'no_email');

    expect(mailer.sent, hasLength(1));
    final mail = mailer.sent.single;
    expect(mail.to, _address);
    expect(mail.pilotName, 'Alex Rivera');
    expect(mail.contestName, 'Spring Open');

    final invitations = (await listing())['invitations'] as List;
    final alex = invitations.cast<Map<String, Object?>>().singleWhere(
      (i) => i['participation_id'] == _withEmailPart,
    );
    expect(alex['link'], mail.link);
    expect(alex['email_status'], 'accepted');
    final blake = invitations.cast<Map<String, Object?>>().singleWhere(
      (i) => i['participation_id'] == _noEmailPart,
    );
    expect(blake['email_status'], isNull);
  });

  test(
    'stores the outcome without the address, the link or the text',
    () async {
      await email('send-1', [_withEmailPart]);
      final stored = await Repository(api.database).invitationRepository
          .listForParticipation(core.Id.parse(_withEmailPart));
      final text = jsonEncode(stored.single.deliveryOutcomes);
      expect(stored.single.deliveryOutcomes.single['status'], 'accepted');
      expect(stored.single.deliveryOutcomes.single['message_id'], 'msg-1');
      expect(text, isNot(contains(_address)));
      expect(text, isNot(contains(mailer.sent.single.link)));
      expect(text, isNot(contains('Spring Open')));
    },
  );

  test('a repeated request id sends nothing and reports the stored '
      'outcome', () async {
    await email('send-1', [_withEmailPart]);
    final (status, body) = await email('send-1', [_withEmailPart]);
    expect(status, 200);
    expect(mailer.sent, hasLength(1));
    final result = resultFor(body, _withEmailPart);
    expect(result['status'], 'accepted');
    expect(result['repeated'], isTrue);
  });

  test('a resend with a new request id sends the same link again', () async {
    await email('send-1', [_withEmailPart]);
    await email('send-2', [_withEmailPart]);
    expect(mailer.sent, hasLength(2));
    expect(mailer.sent.last.link, mailer.sent.first.link);
  });

  test('two requests with one id at the same time send once', () async {
    await Future.wait([
      email('send-1', [_withEmailPart]),
      email('send-1', [_withEmailPart]),
    ]);
    expect(mailer.sent, hasLength(1));
  });

  for (final (name, status) in [
    ('rejected', core.InvitationEmailStatus.rejected),
    ('unavailable', core.InvitationEmailStatus.unavailable),
    ('unconfirmed', core.InvitationEmailStatus.unconfirmed),
  ]) {
    test('a $name send is recorded and the link still works', () async {
      final before = (await listing())['invitations'] as List;
      mailer.result = core.InvitationMailResult(status);
      final (code, body) = await email('send-1', [_withEmailPart]);
      expect(code, 200);
      expect(resultFor(body, _withEmailPart)['status'], name);

      final after = (await listing())['invitations'] as List;
      Object? linkOf(List invitations) => invitations
          .cast<Map<String, Object?>>()
          .singleWhere((i) => i['participation_id'] == _withEmailPart)['link'];
      expect(linkOf(after), linkOf(before));
      expect(
        after.cast<Map<String, Object?>>().firstWhere(
          (i) => i['participation_id'] == _withEmailPart,
        )['email_status'],
        name,
      );
    });
  }

  test('a sender that throws is recorded as unconfirmed', () async {
    mailer.failure = StateError('boom');
    final (status, body) = await email('send-1', [_withEmailPart]);
    expect(status, 200);
    expect(resultFor(body, _withEmailPart)['status'], 'unconfirmed');
  });

  test(
    'a send that was started and never answered is not sent again',
    () async {
      final repository = Repository(api.database);
      final invitation =
          (await repository.invitationRepository.listForParticipation(
            core.Id.parse(_withEmailPart),
          )).single;
      await repository.invitationRepository.updateDeliveryOutcomes(
        invitation.id,
        (current) => [
          ...current,
          {
            'request_id': 'send-1',
            'channel': 'email',
            'status': 'sending',
            'at': DateTime.now().toUtc().toIso8601String(),
          },
        ],
      );
      final (status, body) = await email('send-1', [_withEmailPart]);
      expect(status, 200);
      expect(mailer.sent, isEmpty);
      expect(resultFor(body, _withEmailPart)['status'], 'unconfirmed');
    },
  );

  test('writing an outcome does not undo a redemption', () async {
    final repository = Repository(api.database);
    final invitation =
        (await repository.invitationRepository.listForParticipation(
          core.Id.parse(_withEmailPart),
        )).single;
    final stored = await repository.invitationRepository.updateDeliveryOutcomes(
      invitation.id,
      (current) => [
        ...current,
        {'request_id': 'x', 'channel': 'email', 'status': 'accepted'},
      ],
    );
    expect(stored, hasLength(1));
    final after = await repository.invitationRepository.findById(invitation.id);
    expect(after!.deliveryOutcomes, stored);
    expect(
      after.toSyncJson()..remove('delivery_outcomes'),
      invitation.toSyncJson()..remove('delivery_outcomes'),
    );
    expect(
      await repository.invitationRepository.updateDeliveryOutcomes(
        core.Id.create(),
        (current) => current,
      ),
      isNull,
    );
  });

  test('answers 409 when the server cannot send email', () async {
    handler = build(withMailer: false);
    final (status, body) = await email('send-1', [_withEmailPart]);
    expect(status, 409);
    expect(body.toString(), contains('email_not_available'));
  });

  test('refuses an unknown participation without sending anything', () async {
    final (status, _) = await email('send-1', [
      _withEmailPart,
      core.Id.create().value,
    ]);
    expect(status, 404);
    expect(mailer.sent, isEmpty);
  });

  test('a participation with no invitation is skipped', () async {
    final repository = Repository(api.database);
    final invitation =
        (await repository.invitationRepository.listForParticipation(
          core.Id.parse(_noEmailPart),
        )).single;
    await repository.invitationRepository.save(
      core.Invitation.fromJson({
        ...invitation.toSyncJson(),
        'state': 'Revoked',
        'revoked_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    final (status, body) = await email('send-1', [_noEmailPart]);
    expect(status, 200);
    expect(resultFor(body, _noEmailPart)['skipped'], 'no_invitation');
  });

  Future<List<core.AuditEvent>> deliveryAudits() => Repository(api.database)
      .auditEventRepository
      .listForContest(
        core.Id.parse(_contestId),
        action: core.AuditAction.invitationDeliveryRequested,
      );

  Future<String> credentialOfAlex() async {
    final invitations = (await listing())['invitations'] as List;
    final link =
        invitations.cast<Map<String, Object?>>().singleWhere(
              (i) => i['participation_id'] == _withEmailPart,
            )['link']
            as String;
    return link.split('/').last;
  }

  core.InvitationService opener() => core.InvitationService(
    Repository(api.database),
    core.InvitationCodec.fromText(_secret),
  );

  test('a pilot opening the link keeps the send claim, so a retry sends '
      'nothing', () async {
    final repository = Repository(api.database);
    final invitation =
        (await repository.invitationRepository.listForParticipation(
          core.Id.parse(_withEmailPart),
        )).single;
    // A claim stored, the send not yet answered.
    await repository.invitationRepository.updateDeliveryOutcomes(
      invitation.id,
      (current) => [
        ...current,
        {
          'request_id': 'send-1',
          'channel': 'email',
          'status': 'sending',
          'at': DateTime.now().toUtc().toIso8601String(),
        },
      ],
    );
    await opener().resolve(await credentialOfAlex());

    final after = await repository.invitationRepository.findById(invitation.id);
    expect(after!.redeemedByAccountId, isNotNull);
    expect(after.deliveryOutcomes.single['request_id'], 'send-1');
    final (_, body) = await email('send-1', [_withEmailPart]);
    expect(mailer.sent, isEmpty);
    expect(resultFor(body, _withEmailPart)['status'], 'unconfirmed');
  });

  test('opening the link while the email is sent keeps every outcome and '
      'sends once', () async {
    final credential = await credentialOfAlex();
    for (var round = 0; round < 3; round++) {
      await Future.wait([
        email('send-$round', [_withEmailPart]),
        opener().resolve(credential),
        opener().resolve(credential),
      ]);
    }
    expect(mailer.sent, hasLength(3));
    final invitation =
        (await Repository(api.database).invitationRepository
                .listForParticipation(core.Id.parse(_withEmailPart)))
            .single;
    expect(invitation.deliveryOutcomes.map((o) => o['request_id']), [
      'send-0',
      'send-1',
      'send-2',
    ]);
    expect(
      invitation.deliveryOutcomes.map((o) => o['status']),
      everyElement('accepted'),
    );
    expect(invitation.redeemedByAccountId, isNotNull);
  });

  test('stores one delivery audit event with the claim, whatever the '
      'send does', () async {
    await email('send-1', [_withEmailPart]);
    mailer.failure = StateError('boom');
    await email('send-2', [_withEmailPart]);
    await email('send-2', [_withEmailPart]); // a repeat adds none
    final audits = await deliveryAudits();
    expect(audits, hasLength(2));
    expect(audits.every((a) => a.actorId == api.director), isTrue);
    expect(audits.every((a) => a.entityType == 'Invitation'), isTrue);
  });

  test(
    'an email that is skipped or refused stores no delivery audit',
    () async {
      await email('send-1', [_noEmailPart]);
      await email('send-2', [core.Id.create().value]);
      expect(await deliveryAudits(), isEmpty);
    },
  );

  test('a claim stored while a pilot opens the link is not erased', () async {
    final repository = Repository(api.database);
    final invitation =
        (await repository.invitationRepository.listForParticipation(
          core.Id.parse(_withEmailPart),
        )).single;
    // The service reads the invitation, then asks the clock for the time of
    // the open: the claim is stored in that gap, before the open is saved.
    Future<List<Map<String, Object?>>?>? claim;
    final racing = core.InvitationService(
      repository,
      core.InvitationCodec.fromText(_secret),
      clock: () {
        claim ??= repository.invitationRepository.updateDeliveryOutcomes(
          invitation.id,
          (current) => [
            ...current,
            {
              'request_id': 'send-1',
              'channel': 'email',
              'status': 'sending',
              'at': DateTime.now().toUtc().toIso8601String(),
            },
          ],
        );
        return DateTime.now().toUtc();
      },
    );
    await racing.resolve(await credentialOfAlex());
    await claim;

    final after = await repository.invitationRepository.findById(invitation.id);
    expect(after!.deliveryOutcomes.map((o) => o['request_id']), ['send-1']);
    expect(after.redeemedByAccountId, isNotNull);
    await email('send-1', [_withEmailPart]);
    expect(mailer.sent, isEmpty);
  });
}
