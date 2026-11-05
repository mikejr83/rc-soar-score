import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/publication/publication_actions.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/matrix_test_support.dart';

void main() {
  final contest = matrixContest();

  PublicationActions actions(List<String> ids, {bool fail = false}) =>
      PublicationActions(
        ApiClient(
          baseUrl: Uri.parse('http://localhost'),
          httpClient: MockClient((request) async {
            ids.add(
              (jsonDecode(request.body)
                      as Map<String, dynamic>)['client_mutation_id']
                  as String,
            );
            if (fail) {
              throw http.ClientException('lost', request.url);
            }
            return http.Response(
              jsonEncode({'visibility': 'Unlisted'}),
              201,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );

  test('retrying after a lost response reuses the mutation id', () async {
    final ids = <String>[];
    final lost = await actions(ids, fail: true).publish(contest);
    expect(lost.failure, PublicationFailure.network);
    await actions(ids).publish(contest);
    expect(ids, hasLength(2));
    expect(ids[1], ids[0]);
  });

  test('an update after seeing a new copy gets a new mutation id', () async {
    final ids = <String>[];
    await actions(ids).publish(contest);
    await actions(ids).publish(contest, projectionRevision: 1);
    expect(ids[1], isNot(ids[0]));
  });

  test('a contest that moved on gets a new mutation id', () {
    final json = contest.toJson();
    json['revision'] = contest.revision + 1;
    final moved = Contest.fromJson(json);
    expect(
      PublicationActions.mutationId(moved, 0),
      isNot(PublicationActions.mutationId(contest, 0)),
    );
  });

  test('an unexpected error is logged and reported as a failure', () async {
    final records = <LogRecord>[];
    final sub = Logger('PublicationActions').onRecord.listen(records.add);
    addTearDown(sub.cancel);
    final result = await PublicationActions(
      ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient((request) async => throw StateError('bug')),
      ),
    ).publish(contest);
    expect(result.failure, PublicationFailure.other);
    expect(records.single.level, Level.SEVERE);
    expect(records.single.error, isA<StateError>());
  });

  PublicationActions answering(int status, {bool signedIn = false}) =>
      PublicationActions(
        signedIn: signedIn,
        ApiClient(
          baseUrl: Uri.parse('http://localhost'),
          httpClient: MockClient(
            (request) async => http.Response(
              jsonEncode({
                'error': {'code': 'x', 'message': 'no'},
              }),
              status,
              headers: {'content-type': 'application/json'},
            ),
          ),
        ),
      );

  test('a 401 means sign in', () async {
    final outcome = await answering(401).publish(contest);
    expect(outcome.failure, PublicationFailure.signInRequired);
  });

  test('a 401 while signed in means the sign-in expired', () async {
    final outcome = await answering(401, signedIn: true).publish(contest);
    expect(outcome.failure, PublicationFailure.signInExpired);
  });

  test('a 404 on publish means the server has no such contest yet', () async {
    final outcome = await answering(404).publish(contest);
    expect(outcome.failure, PublicationFailure.notSynced);
  });

  test('a 404 on withdrawing a request still means nothing pending', () async {
    final outcome = await answering(404).withdrawDelisting(contest.id);
    expect(outcome.failure, PublicationFailure.nothingPending);
  });
}
