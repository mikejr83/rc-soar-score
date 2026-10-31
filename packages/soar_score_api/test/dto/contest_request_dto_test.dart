import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final contestId = Id.parse('019c0000-0000-7000-8000-000000000020');

  group('CreateContestRequest', () {
    final request = CreateContestRequest(
      id: contestId,
      name: 'Spring Open',
      startDateTime: DateTime.utc(2026, 10, 17, 14),
      endDateTime: DateTime.utc(2026, 10, 18, 22),
      timezone: 'America/Denver',
      city: 'Boulder',
    );

    test('encodes snake_case keys, the id text and UTC times', () {
      expect(request.toJson(), {
        'id': contestId.value,
        'name': 'Spring Open',
        'start_date_time': '2026-10-17T14:00:00Z',
        'end_date_time': '2026-10-18T22:00:00Z',
        'timezone': 'America/Denver',
        'host': null,
        'city': 'Boulder',
        'state': null,
        'country': null,
      });
    });

    test('round-trips', () {
      final decoded = CreateContestRequest.fromJson(request.toJson());
      expect(decoded.id, contestId);
      expect(decoded.startDateTime, request.startDateTime);
      expect(decoded.city, 'Boulder');
      expect(decoded.host, isNull);
    });

    test('a missing required field fails to decode', () {
      final json = request.toJson()..remove('name');
      expect(() => CreateContestRequest.fromJson(json), throwsA(anything));
    });
  });

  group('UpdateContestRequest', () {
    test('round-trips and carries the base revision', () {
      final request = UpdateContestRequest(
        baseRevision: 3,
        name: 'Renamed',
        startDateTime: DateTime.utc(2026, 10, 17, 14),
        endDateTime: DateTime.utc(2026, 10, 18, 22),
      );

      final json = request.toJson();
      expect(json['base_revision'], 3);
      expect(UpdateContestRequest.fromJson(json).baseRevision, 3);
      expect(json.containsKey('timezone'), isFalse);
    });
  });

  group('ContestActionRequest', () {
    test('uses the action names of the wire format', () {
      expect(
        const ContestActionRequest(
          action: ContestAction.openScoring,
          baseRevision: 1,
        ).toJson(),
        {'action': 'openScoring', 'base_revision': 1},
      );
      expect(
        ContestActionRequest.fromJson({
          'action': 'complete',
          'base_revision': 2,
        }).action,
        ContestAction.complete,
      );
    });

    test('names the results hiding actions', () {
      for (final action in [
        ContestAction.hideResults,
        ContestAction.showResults,
      ]) {
        final json = ContestActionRequest(
          action: action,
          baseRevision: 1,
        ).toJson();
        expect(json['action'], action.name);
        expect(ContestActionRequest.fromJson(json).action, action);
      }
    });

    test('an unknown action fails to decode', () {
      expect(
        () => ContestActionRequest.fromJson({
          'action': 'explode',
          'base_revision': 0,
        }),
        throwsA(anything),
      );
    });
  });

  group('ApiHttpError.error', () {
    ApiHttpError failure(String body) => ApiHttpError(
      'failed',
      statusCode: 409,
      body: body,
      requestUri: Uri.parse('http://localhost/x'),
    );

    test('parses the server error body', () {
      final error = failure(
        '{"error":{"code":"stale_revision","message":"m","requestId":"r1"}}',
      ).error;

      expect(error?.code, 'stale_revision');
      expect(error?.message, 'm');
      expect(error?.requestId, 'r1');
    });

    test('is null for anything else', () {
      expect(failure('nope').error, isNull);
      expect(failure('{"error":"text"}').error, isNull);
      expect(failure('[]').error, isNull);
    });
  });
}
