import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
final _other = Id.parse('019c0000-0000-7000-8000-000000000002');
const _profileId = '019c0000-0000-7000-8000-000000000101';

Map<String, Object?> _createBody({
  String? id,
  String firstName = 'Ada',
  Map<String, Object?> extra = const {},
}) => {
  'id': id ?? _profileId,
  'first_name': firstName,
  'last_name': 'Lovelace',
  ...extra,
};

void main() {
  late HandlerHarness api;

  setUp(() => api = HandlerHarness(_owner));

  Future<Map<String, Object?>> create([Map<String, Object?>? body]) async {
    final response = await api.send(
      'POST',
      '/participants',
      body: body ?? _createBody(),
    );
    expect(response.statusCode, 201);
    return api.json(response);
  }

  group('POST /participants', () {
    test('creates a profile owned by the principal', () async {
      final body = await create(
        _createBody(
          extra: {'club': ' Front Range ', 'email': 'ADA@Example.com'},
        ),
      );

      expect(body['id'], _profileId);
      expect(body['owner_account_id'], _owner.value);
      expect(body['club'], 'Front Range');
      expect(body['email'], 'ada@example.com');
      expect(body['revision'], 0);
    });

    test('records the principal as the actor', () async {
      await create();

      final metadata = api.repository.participantProfiles.savedWith.single;
      expect(metadata.actorId, _owner);
      expect(metadata.authority, Authority.director);
    });

    test('repeating the request returns the same profile', () async {
      final first = await create();
      final second = await create();

      expect(second, first);
      expect(api.repository.participantProfiles.savedWith, hasLength(1));
    });

    test('the same id with other content is a 409', () async {
      await create();

      final response = await api.send(
        'POST',
        '/participants',
        body: _createBody(firstName: 'Grace'),
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'already_stored');
    });

    test('rejects malformed bodies with 400', () async {
      for (final body in <Object>[
        <String, Object?>{},
        _createBody(id: 'nope'),
        _createBody(firstName: '  '),
        _createBody(extra: {'last_name': 7}),
      ]) {
        final response = await api.send('POST', '/participants', body: body);
        expect(response.statusCode, 400, reason: '$body');
      }
      expect(api.repository.participantProfiles.savedWith, isEmpty);
    });
  });

  group('reading', () {
    test('lists only the principal\'s profiles', () async {
      await create();
      // A profile of another director in the same store.
      api.repository.participantProfiles.profiles[Id.parse(
        '019c0000-0000-7000-8000-000000000103',
      )] = ParticipantProfile(
        id: Id.parse('019c0000-0000-7000-8000-000000000103'),
        ownerAccountId: _other,
        firstName: 'Other',
        lastName: 'Director',
        createdAt: DateTime.utc(2026, 9),
        updatedAt: DateTime.utc(2026, 9),
      );

      final list = await api.json(await api.send('GET', '/participants'));

      expect(list['participants'], hasLength(1));
    });

    test('another director\'s profile is a 404', () async {
      final id = Id.parse('019c0000-0000-7000-8000-000000000103');
      api.repository.participantProfiles.profiles[id] = ParticipantProfile(
        id: id,
        ownerAccountId: _other,
        firstName: 'Other',
        lastName: 'Director',
        createdAt: DateTime.utc(2026, 9),
        updatedAt: DateTime.utc(2026, 9),
      );

      final response = await api.send('GET', '/participants/${id.value}');

      expect(response.statusCode, 404);
    });
  });

  group('PUT /participants/{id}', () {
    test('replaces the details and bumps the revision', () async {
      await create(_createBody(extra: {'club': 'Old Club'}));

      final response = await api.send(
        'PUT',
        '/participants/$_profileId',
        body: {'base_revision': 0, 'first_name': 'Ada', 'last_name': 'Byron'},
      );

      expect(response.statusCode, 200);
      final body = await api.json(response);
      expect(body['last_name'], 'Byron');
      expect(body['club'], isNull);
      expect(body['revision'], 1);
    });

    test('a stale base revision is a 409', () async {
      await create();

      final response = await api.send(
        'PUT',
        '/participants/$_profileId',
        body: {'base_revision': 5, 'first_name': 'Ada', 'last_name': 'L'},
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'stale_revision');
    });
  });

  group('DELETE /participants/{id}', () {
    test('deletes a profile that is in no contest', () async {
      await create();

      final response = await api.send('DELETE', '/participants/$_profileId');

      expect(response.statusCode, 204);
      expect(
        (await api.send('GET', '/participants/$_profileId')).statusCode,
        404,
      );
    });

    test('a profile that is in a contest is a 409', () async {
      await create();
      api.repository.participations.participations[Id.create()] =
          ContestParticipation(
            id: Id.create(),
            contestId: Id.create(),
            participantProfileId: Id.parse(_profileId),
            roleId: SystemRoles.pilotId,
            roleName: 'Pilot',
            scoringUuid: ScoringUuid.create(),
          );

      final response = await api.send('DELETE', '/participants/$_profileId');

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'has_participations');
    });
  });
}
