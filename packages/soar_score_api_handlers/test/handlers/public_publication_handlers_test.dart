import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../stubs/stub_contest_repository.dart';
import '../stubs/stub_repository.dart';

/// A repository whose public listing is empty, enough to answer `/publications`.
class _EmptyListing extends StubRepository {
  _EmptyListing() : super(StubContestRepository());

  @override
  core.PublicationIdentityRepository get publicationIdentityRepository =>
      _EmptyIdentities();

  @override
  core.PublicationProjectionRepository get publicationProjectionRepository =>
      _NoProjections();
}

class _EmptyIdentities implements core.PublicationIdentityRepository {
  @override
  Future<List<core.PublicationIdentity>> listPublic(
    core.PublicationListQuery query,
  ) async => [];

  @override
  Future<int> countPublicActive({
    DateTime? startsOnOrAfter,
    DateTime? endsOnOrAfter,
    required DateTime startsBefore,
  }) async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

class _NoProjections implements core.PublicationProjectionRepository {
  @override
  Future<Map<core.Id, core.PublicationProjection>> findByIds(
    Iterable<core.Id> ids,
  ) async => {};

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

const _publicationId = '019c0000-0000-7000-8000-0000000000d1';

/// The HTTP side of the public reads. What they return is covered against
/// the real repositories in `soar_score_data`.
void main() {
  Handler build({required bool publishingEnabled}) => buildApiHandler(
    name: 'soar_score_server',
    displayName: 'Soar Score API Server',
    version: '0.1.0',
    repository: StubRepository(StubContestRepository()),
    // Everything under /api/v1 is refused, so a 2xx or 4xx other than 401
    // from /public shows it sits outside the sign-in.
    authMiddleware: (inner) =>
        (request) => Response(401),
    publishingEnabled: publishingEnabled,
  );

  Future<Response> get(Handler handler, String path) => Future.value(
    handler(Request('GET', Uri.parse('http://localhost/public$path'))),
  );

  Future<String> codeOf(Response response) async =>
      ((jsonDecode(await response.readAsString())
                  as Map<String, Object?>)['error']!
              as Map<String, Object?>)['code']!
          as String;

  group('on a server that does not publish', () {
    final handler = build(publishingEnabled: false);

    for (final path in ['/publications', '/publications/$_publicationId']) {
      test('GET $path answers 409 publishing_not_available', () async {
        final response = await get(handler, path);

        expect(response.statusCode, 409);
        expect(await codeOf(response), 'publishing_not_available');
      });
    }
  });

  group('on a server that publishes', () {
    final handler = build(publishingEnabled: true);

    test('the reads are outside the sign-in', () async {
      final api = await handler(
        Request('GET', Uri.parse('http://localhost/api/v1/ping')),
      );
      final response = await get(handler, '/publications/not-an-id');

      expect(api.statusCode, 401);
      expect(response.statusCode, isNot(401));
    });

    test('an id that is not an id is a 400', () async {
      expect((await get(handler, '/publications/not-an-id')).statusCode, 400);
    });

    test('the listing is cacheable for 30 seconds; errors are not', () async {
      final listing = buildApiHandler(
        name: 'soar_score_server',
        displayName: 'Soar Score API Server',
        version: '0.1.0',
        repository: _EmptyListing(),
        authMiddleware: (inner) =>
            (request) => Response(401),
        publishingEnabled: true,
      );

      final ok = await get(listing, '/publications?limit=5');
      final bad = await get(listing, '/publications?limit=0');

      expect(ok.statusCode, 200);
      expect(ok.headers['cache-control'], 'public, max-age=30');
      expect(jsonDecode(await ok.readAsString()), {
        'publications': <Object?>[],
        'summary': {'recent_count': 0},
      });
      expect(bad.statusCode, 400);
      expect(bad.headers['cache-control'], isNull);
    });

    for (final query in [
      'limit=0',
      'limit=x',
      'offset=-1',
      'offset=1.5',
      'from=2026-11-06x',
      'from=2026-13-01',
      'to=2026-02-30',
      'today=tomorrow',
      'from=2026-11-09&to=2026-11-06',
    ]) {
      test('listing with $query is a 400', () async {
        final response = await get(handler, '/publications?$query');

        expect(response.statusCode, 400);
        expect(await codeOf(response), 'invalid_request');
      });
    }
  });
}
