import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../stubs/stub_contest_repository.dart';
import '../stubs/stub_repository.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
final _contestId = '019c0000-0000-7000-8000-000000000020';

Map<String, Object?> _createBody({
  String? id,
  String name = 'Spring Open',
  Map<String, Object?> extra = const {},
}) => {
  'id': id ?? _contestId,
  'name': name,
  'start_date_time': '2026-10-17T14:00:00.000Z',
  'end_date_time': '2026-10-18T22:00:00.000Z',
  'timezone': 'America/Denver',
  ...extra,
};

void main() {
  late StubContestRepository contests;
  late Handler handler;

  setUp(() {
    contests = StubContestRepository();
    handler = buildApiHandler(
      name: 'soar_score_server',
      displayName: 'Soar Score API Server',
      version: '0.1.0',
      repository: StubRepository(contests),
      authMiddleware: fixedPrincipal(Principal(accountId: _owner)),
    );
  });

  Future<Response> send(
    String method,
    String path, {
    Object? body,
    Handler? through,
  }) async => (through ?? handler)(
    Request(
      method,
      Uri.parse('http://localhost/api/v1$path'),
      body: body == null ? null : (body is String ? body : jsonEncode(body)),
    ),
  );

  Future<Map<String, Object?>> json(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, Object?>;

  Future<Map<String, Object?>> create() async {
    final response = await send('POST', '/contests', body: _createBody());
    expect(response.statusCode, 201);
    return json(response);
  }

  Map<String, Object?> errorOf(Map<String, Object?> body) =>
      body['error'] as Map<String, Object?>;

  group('POST /contests', () {
    test('creates a Created contest owned by the principal', () async {
      final body = await create();

      expect(body['id'], _contestId);
      expect(body['name'], 'Spring Open');
      expect(body['lifecycle_state'], 'Created');
      expect(body['owner_account_id'], _owner.value);
      expect(body['revision'], 0);
    });

    test(
      'records the principal as the actor with Director authority',
      () async {
        await create();

        final metadata = contests.savedWith.single;
        expect(metadata.actorId, _owner);
        expect(metadata.authority, Authority.director);
      },
    );

    test('repeating the request returns the same contest', () async {
      final first = await create();
      final second = await create();

      expect(second, first);
      expect(contests.savedWith, hasLength(1));
    });

    test('the same id with other content is a 409', () async {
      await create();

      final response = await send(
        'POST',
        '/contests',
        body: _createBody(name: 'Something else'),
      );

      expect(response.statusCode, 409);
      expect(errorOf(await json(response))['code'], 'already_stored');
    });

    test('rejects malformed bodies with 400', () async {
      for (final body in <Object>[
        'not json',
        '[1, 2]',
        <String, Object?>{},
        _createBody(id: 'not-a-uuid'),
        _createBody(extra: {'name': 42}),
        _createBody(extra: {'start_date_time': 'yesterday'}),
        _createBody(name: '   '),
        _createBody(
          extra: {
            'start_date_time': '2026-10-19T00:00:00Z',
            'end_date_time': '2026-10-18T00:00:00Z',
          },
        ),
      ]) {
        final response = await send('POST', '/contests', body: body);
        expect(response.statusCode, 400, reason: '$body');
        expect(errorOf(await json(response))['code'], 'invalid_request');
      }
      expect(contests.savedWith, isEmpty);
    });
  });

  group('GET /contests', () {
    test('lists contests and fetches one by id', () async {
      await create();

      final list = await json(await send('GET', '/contests'));
      expect(list['contests'], hasLength(1));

      final one = await send('GET', '/contests/$_contestId');
      expect(one.statusCode, 200);
      expect((await json(one))['id'], _contestId);
    });

    test('an unknown contest is 404', () async {
      final response = await send('GET', '/contests/$_contestId');

      expect(response.statusCode, 404);
      expect(errorOf(await json(response))['code'], 'not_found');
    });

    test('an invalid id is 400', () async {
      expect((await send('GET', '/contests/nope')).statusCode, 400);
    });
  });

  group('PUT /contests/{id}', () {
    Map<String, Object?> updateBody({int base = 0, String name = 'Renamed'}) =>
        {
          'base_revision': base,
          'name': name,
          'start_date_time': '2026-10-17T14:00:00.000Z',
          'end_date_time': '2026-10-18T22:00:00.000Z',
          'city': 'Boulder',
        };

    test('replaces the details and bumps the revision', () async {
      await create();

      final response = await send(
        'PUT',
        '/contests/$_contestId',
        body: updateBody(),
      );

      expect(response.statusCode, 200);
      final body = await json(response);
      expect(body['name'], 'Renamed');
      expect(body['city'], 'Boulder');
      expect(body['timezone'], 'America/Denver');
      expect(body['revision'], 1);
      expect(contests.savedWith.last.actorId, _owner);
    });

    test('a stale base revision is 409 and changes nothing', () async {
      await create();
      await send('PUT', '/contests/$_contestId', body: updateBody());

      final response = await send(
        'PUT',
        '/contests/$_contestId',
        body: updateBody(name: 'Late'),
      );

      expect(response.statusCode, 409);
      expect(errorOf(await json(response))['code'], 'stale_revision');
      final stored = await contests.findById(Id.parse(_contestId));
      expect(stored!.name, 'Renamed');
    });

    test('an unknown contest is 404', () async {
      final response = await send(
        'PUT',
        '/contests/$_contestId',
        body: updateBody(),
      );
      expect(response.statusCode, 404);
    });

    test('a body without base_revision is 400', () async {
      await create();
      final body = updateBody()..remove('base_revision');

      final response = await send('PUT', '/contests/$_contestId', body: body);

      expect(response.statusCode, 400);
    });
  });

  group('POST /contests/{id}/actions', () {
    Future<Response> act(String action, {int base = 0}) => send(
      'POST',
      '/contests/$_contestId/actions',
      body: {'action': action, 'base_revision': base},
    );

    test('locks the contest', () async {
      await create();

      final response = await act('lock');

      expect(response.statusCode, 200);
      final body = await json(response);
      expect(body['admin_lock'], 'Locked');
      expect(body['revision'], 1);
      expect(contests.savedWith.last.actorId, _owner);
    });

    test('a refused action is 409 with the rule that refused it', () async {
      await create();

      final response = await act('complete');

      expect(response.statusCode, 409);
      expect(errorOf(await json(response))['code'], 'invalid_transition');
    });

    test('a stale base revision is 409', () async {
      await create();
      await act('lock');

      final response = await act('unlock');

      expect(response.statusCode, 409);
      expect(errorOf(await json(response))['code'], 'stale_revision');
    });

    test('an unknown action is 400', () async {
      await create();
      expect((await act('explode')).statusCode, 400);
    });

    test('an unknown contest is 404', () async {
      expect((await act('lock')).statusCode, 404);
    });
  });

  test(
    'writes without an auth layer are a server error, not a write',
    () async {
      final unprotected = buildApiHandler(
        name: 'n',
        displayName: 'N',
        version: '1',
        repository: StubRepository(contests),
      );

      final response = await send(
        'POST',
        '/contests',
        body: _createBody(),
        through: unprotected,
      );

      expect(response.statusCode, 500);
      expect(contests.savedWith, isEmpty);
    },
  );
}
