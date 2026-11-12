import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = '019c0000-0000-7000-8000-0000000000c1';

/// Stores the contest, so a request reaches its body: the director check
/// comes before the body is read.
Future<void> _seed(HandlerHarness api) => api.contests.save(
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

/// The HTTP side of the publication routes. What publishing stores is
/// covered against the real repositories in `soar_score_data`.
void main() {
  group('on a server that does not publish', () {
    late HandlerHarness api;

    setUp(() => api = HandlerHarness(_owner));

    for (final (method, path, body) in [
      (
        'POST',
        '/contests/$_contestId/publication',
        {'client_mutation_id': 'm-1', 'source_contest_revision': 1},
      ),
      ('GET', '/contests/$_contestId/publication', null),
      (
        'PATCH',
        '/contests/$_contestId/publication/visibility',
        {'visibility': 'Public'},
      ),
      ('GET', '/contests/$_contestId/publication/projections', null),
      (
        'POST',
        '/contests/$_contestId/publication/delist-requests',
        <String, Object?>{},
      ),
      (
        'GET',
        '/contests/$_contestId/publication/delist-requests/current',
        null,
      ),
      (
        'DELETE',
        '/contests/$_contestId/publication/delist-requests/current',
        null,
      ),
    ]) {
      test('$method $path answers 409 publishing_not_available', () async {
        final response = await api.send(method, path, body: body);

        expect(response.statusCode, 409);
        expect(
          (await api.errorOf(response))['code'],
          'publishing_not_available',
        );
      });
    }
  });

  group('on a server that publishes', () {
    late HandlerHarness api;

    setUp(() => api = HandlerHarness(_owner, publishingEnabled: true));

    test('a publish without a mutation id is a 400', () async {
      await _seed(api);
      final response = await api.send(
        'POST',
        '/contests/$_contestId/publication',
        body: {'source_contest_revision': 1},
      );

      expect(response.statusCode, 400);
      expect((await api.errorOf(response))['code'], 'invalid_request');
    });

    for (final visibility in ['Delisted', 'Everyone', '']) {
      test('visibility "$visibility" is a 400', () async {
        await _seed(api);
        final response = await api.send(
          'PATCH',
          '/contests/$_contestId/publication/visibility',
          body: {'visibility': visibility},
        );

        expect(response.statusCode, 400);
        expect((await api.errorOf(response))['code'], 'invalid_request');
      });
    }

    for (final limit in ['0', '101', 'many']) {
      test('projection history limit "$limit" is a 400', () async {
        final response = await api.send(
          'GET',
          '/contests/$_contestId/publication/projections?limit=$limit',
        );

        expect(response.statusCode, 400);
      });
    }

    for (final (method, path, body) in [
      ('GET', '/contests/$_contestId/publication/projections', null),
      (
        'POST',
        '/contests/$_contestId/publication/delist-requests',
        <String, Object?>{},
      ),
      (
        'GET',
        '/contests/$_contestId/publication/delist-requests/current',
        null,
      ),
      (
        'DELETE',
        '/contests/$_contestId/publication/delist-requests/current',
        null,
      ),
    ]) {
      test('$method $path for an unknown contest is a 404', () async {
        final response = await api.send(method, path, body: body);

        expect(response.statusCode, 404);
      });
    }

    test('a delist request body that is not an object is a 400', () async {
      await _seed(api);
      final response = await api.send(
        'POST',
        '/contests/$_contestId/publication/delist-requests',
        body: {'reason': 5},
      );

      expect(response.statusCode, 400);
    });

    test('a contest that does not exist is a 404', () async {
      final response = await api.send(
        'POST',
        '/contests/$_contestId/publication',
        body: {'client_mutation_id': 'm-1', 'source_contest_revision': 1},
      );

      expect(response.statusCode, 404);
    });
  });
}
