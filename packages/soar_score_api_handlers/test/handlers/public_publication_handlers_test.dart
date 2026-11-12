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

/// Publications by id: one repository answering `/publications/{id}` from
/// what the test puts in it.
class _Publications extends StubRepository {
  _Publications(this.identities, this.projections)
    : super(StubContestRepository());

  final Map<core.Id, core.PublicationIdentity> identities;
  final Map<core.Id, core.PublicationProjection> projections;

  @override
  core.InvitationRepository get invitationRepository => _NoInvitations();

  @override
  core.PublicationIdentityRepository get publicationIdentityRepository =>
      _IdentitiesById(identities);

  @override
  core.PublicationProjectionRepository get publicationProjectionRepository =>
      _ProjectionsById(projections);

  @override
  core.PublicationParticipantRepository get publicationParticipantRepository =>
      _NoParticipants();
}

class _IdentitiesById implements core.PublicationIdentityRepository {
  _IdentitiesById(this.identities);
  final Map<core.Id, core.PublicationIdentity> identities;

  @override
  Future<core.PublicationIdentity?> findById(core.Id id) async =>
      identities[id];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

class _ProjectionsById implements core.PublicationProjectionRepository {
  _ProjectionsById(this.projections);
  final Map<core.Id, core.PublicationProjection> projections;

  @override
  Future<core.PublicationProjection?> findById(core.Id id) async =>
      projections[id];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

class _NoInvitations implements core.InvitationRepository {
  @override
  Future<Map<core.Id, DateTime>> latestIssuedAtForContests(
    Iterable<core.Id> contestIds,
  ) async => {};

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

class _NoParticipants implements core.PublicationParticipantRepository {
  @override
  Future<List<core.PublicationParticipant>> listForPublication(
    core.Id publicationId,
  ) async => [];

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
      expect(bad.headers['cache-control'], 'no-store');
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

  group('cache policy of the detail read (#906)', () {
    final visibleId = core.Id.parse('019c0000-0000-7000-8000-0000000000a1');
    final delistedId = core.Id.parse('019c0000-0000-7000-8000-0000000000a2');
    final pendingId = core.Id.parse('019c0000-0000-7000-8000-0000000000a3');
    final projectionId = core.Id.parse('019c0000-0000-7000-8000-0000000000b1');
    final publishedAt = DateTime.utc(2026, 11, 7, 12);

    core.PublicationIdentity identity(
      core.Id id,
      core.PublicationVisibility visibility, {
      core.Id? projection,
    }) => core.PublicationIdentity(
      id: id,
      visibility: visibility,
      verificationEmail: 'x@example.com',
      currentProjectionId: projection,
      publishedAt: publishedAt,
    );

    final handler = buildApiHandler(
      name: 'soar_score_server',
      displayName: 'Soar Score API Server',
      version: '0.1.0',
      repository: _Publications(
        {
          visibleId: identity(
            visibleId,
            core.PublicationVisibility.public,
            projection: projectionId,
          ),
          delistedId: identity(
            delistedId,
            core.PublicationVisibility.delisted,
            projection: projectionId,
          ),
          pendingId: identity(pendingId, core.PublicationVisibility.public),
        },
        {
          projectionId: core.PublicationProjection(
            id: projectionId,
            publicationId: visibleId,
            projectionRevision: 1,
            contestRevision: 0,
            configRevision: 0,
            matrixRevision: 0,
            disciplineType: core.DisciplineType.f5j,
            disciplineRulesVersion: 1,
            calculationVersion: '1',
            contestIdentity: {'name': 'Cache Cup', 'start': '2026-11-07'},
            publishedAt: publishedAt,
            clientMutationId: 'm1',
          ),
        },
      ),
      authMiddleware: (inner) =>
          (request) => Response(401),
      publishingEnabled: true,
    );

    Future<Response> read(core.Id id) => Future.value(
      handler(
        Request(
          'GET',
          Uri.parse('http://localhost/public/publications/${id.value}'),
        ),
      ),
    );

    test('a shown publication is cacheable for 30 seconds', () async {
      final response = await read(visibleId);
      expect(response.statusCode, 200);
      expect(response.headers['cache-control'], 'public, max-age=30');
    });

    test('a delisted publication is a 403 that is never cached', () async {
      final response = await read(delistedId);

      expect(response.statusCode, 403);
      expect(response.headers['cache-control'], 'no-store');
    });

    test(
      'a publication with no projection is a 403 that is never cached',
      () async {
        final response = await read(pendingId);

        expect(response.statusCode, 403);
        expect(response.headers['cache-control'], 'no-store');
      },
    );

    test('an unknown publication is a 404 that is never cached, and its '
        'body says nothing of the other kind', () async {
      final unknown = await read(
        core.Id.parse('019c0000-0000-7000-8000-0000000000ff'),
      );
      final hidden = await read(delistedId);

      expect(unknown.statusCode, 404);
      expect(unknown.headers['cache-control'], 'no-store');
      expect(await codeOf(unknown), isNot('contest_not_visible'));
      expect(await codeOf(hidden), 'contest_not_visible');
    });

    test('nothing public carries a credential or sets a cookie', () async {
      for (final response in [await read(visibleId), await read(delistedId)]) {
        expect(response.headers.containsKey('set-cookie'), isFalse);
        expect(response.headers['x-robots-tag'], 'noindex, nofollow');
      }
    });
  });
}
