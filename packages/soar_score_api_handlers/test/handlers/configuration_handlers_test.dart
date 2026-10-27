import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../stubs/stub_contest_repository.dart';
import '../stubs/stub_repository.dart';
import 'handler_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = '019c0000-0000-7000-8000-000000000020';

Map<String, Object?> _body({
  int base = 0,
  Map<String, Object?> core = const {},
  Map<String, Object?> discipline = const {'working_time': 600},
  Object? landing,
  String? profile,
}) => {
  'base_revision_number': base,
  'discipline_profile_id': profile ?? SystemDisciplineProfiles.f5jId.value,
  'config': {'core': core, 'discipline': discipline},
  'landing_table_id': ?landing,
};

void main() {
  late StubContestRepository contests;
  late StubRepository repository;
  late Handler handler;

  setUp(() async {
    contests = StubContestRepository();
    repository = StubRepository(contests);
    handler = buildApiHandler(
      name: 'soar_score_server',
      displayName: 'Soar Score API Server',
      version: '0.1.0',
      repository: repository,
      authMiddleware: fixedPrincipal(Principal(accountId: _owner)),
    );
    await contests.save(
      Contest(
        id: Id.parse(_contestId),
        name: 'Spring Open',
        startDateTime: DateTime.utc(2026, 10, 17, 14),
        endDateTime: DateTime.utc(2026, 10, 18, 22),
        timezone: 'America/Denver',
        ownerAccountId: _owner,
        createdAt: DateTime.utc(2026, 9),
        updatedAt: DateTime.utc(2026, 9),
      ),
      metadata: MutationMetadata(
        clientMutationId: 'seed',
        authority: Authority.director,
        clientTime: DateTime.utc(2026, 9),
      ),
    );
  });

  Future<Response> send(String method, String path, {Object? body}) async =>
      handler(
        Request(
          method,
          Uri.parse('http://localhost/api/v1$path'),
          body: body == null ? null : jsonEncode(body),
        ),
      );

  Future<Map<String, Object?>> json(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, Object?>;

  Map<String, Object?> errorOf(Map<String, Object?> body) =>
      body['error'] as Map<String, Object?>;

  Future<Response> save(Object body) =>
      send('POST', '/contests/$_contestId/configuration', body: body);

  group('POST /contests/{id}/configuration', () {
    test('stores revision 1 and returns it with the changed contest', () async {
      final response = await save(_body());

      expect(response.statusCode, 201);
      final body = await json(response);
      final configuration = body['configuration'] as Map<String, Object?>;
      final contest = body['contest'] as Map<String, Object?>;
      expect(configuration['revision_number'], 1);
      expect(configuration['contest_id'], _contestId);
      expect(configuration['created_by'], _owner.value);
      expect(configuration['landing_table_id'], isNotNull);
      expect(contest['lifecycle_state'], 'Configuring');
      expect(contest['revision'], 1);
    });

    test(
      'records the principal as the actor with Director authority',
      () async {
        await save(_body());

        final metadata = contests.savedWith.last;
        expect(metadata.actorId, _owner);
        expect(metadata.authority, Authority.director);
      },
    );

    test('the next revision needs the latest revision number', () async {
      await save(_body());

      final stale = await save(_body());
      expect(stale.statusCode, 409);
      expect(errorOf(await json(stale))['code'], 'stale_revision');

      final next = await save(
        _body(base: 1, discipline: {'working_time': 480}),
      );
      expect(next.statusCode, 201);
      expect(repository.configurations.stored, hasLength(2));
    });

    test('invalid settings are 400 and store nothing', () async {
      for (final body in <Object>[
        _body(discipline: {'working_time': 0}),
        _body(discipline: {'nope': 1}),
        _body(core: {'decimal_places': 9}),
        _body(core: {'teams_enabled': true}),
        _body(profile: '019c0000-0000-7000-8000-0000000000ff'),
        _body(landing: '019c0000-0000-7000-8000-0000000000ff'),
        {'base_revision_number': 0},
        'not json',
      ]) {
        final response = await save(body);
        expect(response.statusCode, 400, reason: '$body');
        expect(errorOf(await json(response))['code'], 'invalid_request');
      }
      expect(repository.configurations.stored, isEmpty);
    });

    test('a different discipline after the first revision is 409', () async {
      await save(_body());

      final response = await save(
        _body(base: 1, profile: SystemDisciplineProfiles.f3jId.value),
      );

      expect(response.statusCode, 409);
      expect(errorOf(await json(response))['code'], 'discipline_fixed');
    });

    test('a locked contest is 409', () async {
      final contest = (await contests.findById(Id.parse(_contestId)))!;
      await contests.save(
        contest.copyWithState(
          adminLock: AdminLock.locked,
          updatedAt: DateTime.utc(2026, 9, 2),
        ),
        metadata: MutationMetadata(
          clientMutationId: 'lock',
          authority: Authority.director,
          clientTime: DateTime.utc(2026, 9, 2),
        ),
      );

      final response = await save(_body());

      expect(response.statusCode, 409);
      expect(errorOf(await json(response))['code'], 'contest_locked');
    });

    test('an unknown contest is 404', () async {
      final response = await send(
        'POST',
        '/contests/019c0000-0000-7000-8000-0000000000ee/configuration',
        body: _body(),
      );
      expect(response.statusCode, 404);
    });
  });

  group('reads', () {
    test('a contest with no configuration has none to read', () async {
      final latest = await send('GET', '/contests/$_contestId/configuration');
      expect(latest.statusCode, 404);

      final list = await send(
        'GET',
        '/contests/$_contestId/configuration/revisions',
      );
      expect(list.statusCode, 200);
      expect((await json(list))['revisions'], isEmpty);
    });

    test('returns the latest revision and the whole history', () async {
      await save(_body());
      await save(_body(base: 1, discipline: {'working_time': 480}));

      final latest = await json(
        await send('GET', '/contests/$_contestId/configuration'),
      );
      expect(latest['revision_number'], 2);
      expect((latest['config'] as Map<String, Object?>)['discipline'], {
        'working_time': 480,
      });

      final list = await json(
        await send('GET', '/contests/$_contestId/configuration/revisions'),
      );
      expect(
        [
          for (final r in list['revisions'] as List)
            (r as Map<String, Object?>)['revision_number'],
        ],
        [1, 2],
      );
    });
  });

  group('contest-scoped authorization', () {
    late TwoAccountApi two;

    setUp(() {
      two = TwoAccountApi(owner: _owner);
      two.storeContest(Id.parse(_contestId));
    });

    test('a foreign director cannot read or save the configuration', () async {
      await two.expectDenied(
        two.outsiderApi,
        'GET',
        '/contests/$_contestId/configuration',
      );
      await two.expectDenied(
        two.outsiderApi,
        'GET',
        '/contests/$_contestId/configuration/revisions',
      );
      await two.expectDenied(
        two.outsiderApi,
        'POST',
        '/contests/$_contestId/configuration',
        body: _body(),
      );

      final own = await two.ownerApi.send(
        'POST',
        '/contests/$_contestId/configuration',
        body: _body(),
      );
      expect(own.statusCode, 201, reason: '${await json(own)}');
    });
  });
}
