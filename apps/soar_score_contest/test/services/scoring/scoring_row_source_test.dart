import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/scoring/scoring_controller.dart';
import 'package:soar_score_contest/services/scoring/scoring_row.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/matrix_test_support.dart';
import '../../support/scoring_test_support.dart';

Future<ScoringController> _open(ScoringServer server) async {
  final c = ScoringController(
    client: ApiClient(
      baseUrl: Uri.parse('http://localhost'),
      httpClient: MockClient(server.handle),
    ),
    contestId: contestId,
    round: 1,
    group: 1,
  );
  addTearDown(c.dispose);
  await c.load();
  return c;
}

ScoringRow _row(ScoringController c, int pilot) =>
    c.rows.firstWhere((r) => r.id == scoringAssignmentId(1, pilot));

void main() {
  const flight = {'time_flown': 540, 'launch_height': 120};

  test('a row knows who first entered its values', () async {
    final server = ScoringServer()
      ..seedScore(scoringAssignmentId(1, 1), flight)
      ..seedPendingSubmission(scoringAssignmentId(1, 2), flight);
    final c = await _open(server);

    final director = _row(c, 1);
    expect(director.sourceAuthority, Authority.director);
    expect(director.isPilotEntry, isFalse);
    final waiting = _row(c, 2);
    expect(waiting.sourceAuthority, Authority.participant);
    expect(waiting.isPilotEntry, isTrue);
  });

  test('an official row still says it came from the pilot', () async {
    final server = ScoringServer()
      ..seedScore(
        scoringAssignmentId(1, 1),
        flight,
        authority: Authority.participant,
      )
      ..seedAutomaticScore(scoringAssignmentId(1, 2), flight);
    final c = await _open(server);

    for (final pilot in [1, 2]) {
      final row = _row(c, pilot);
      expect(row.status, RowStatus.official);
      expect(row.isPilotEntry, isTrue, reason: 'pilot $pilot');
    }
  });

  test('a helper counts as a pilot entry', () async {
    final server = ScoringServer()
      ..seedScore(
        scoringAssignmentId(1, 1),
        flight,
        authority: Authority.helper,
      );
    final c = await _open(server);

    expect(_row(c, 1).isPilotEntry, isTrue);
  });

  test('nothing entered has no source', () async {
    final c = await _open(ScoringServer());

    expect(_row(c, 1).sourceAuthority, isNull);
    expect(_row(c, 1).isPilotEntry, isFalse);
  });

  test('marking a submission official keeps the pilot as its source', () async {
    final server = ScoringServer()
      ..seedPendingSubmission(scoringAssignmentId(1, 1), flight);
    final c = await _open(server);

    expect(await c.markOfficial(_row(c, 1)), isTrue);

    final row = _row(c, 1);
    expect(row.status, RowStatus.official);
    expect(row.isPilotEntry, isTrue);
  });

  test('a director typing over a submission becomes its source', () async {
    final server = ScoringServer()
      ..seedPendingSubmission(scoringAssignmentId(1, 1), flight);
    final c = await _open(server);
    final row = _row(c, 1);
    c.draftOf(row).setTime('9:30');

    expect(await c.save(row), isTrue);

    expect(_row(c, 1).sourceAuthority, Authority.director);
    expect(_row(c, 1).isPilotEntry, isFalse);
  });

  test('review stays hidden until review decisions exist', () async {
    final server = ScoringServer()
      ..seedPendingSubmission(
        scoringAssignmentId(1, 1),
        flight,
        inReview: true,
      );
    final c = await _open(server);

    expect(_row(c, 1).hasOpenReview, isFalse);
  });
}
