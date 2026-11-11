import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/scoring/row_save.dart';
import 'package:soar_score_contest/services/scoring/scoring_controller.dart';
import 'package:soar_score_contest/services/scoring/scoring_row.dart';

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
  final first = scoringAssignmentId(1, 1);
  final second = scoringAssignmentId(1, 2);
  const a = {'time_flown': 540, 'launch_height': 120};
  const b = {'time_flown': 500, 'launch_height': 130};

  test('an untouched row shows a submission that arrived by sync', () async {
    final server = ScoringServer();
    final c = await _open(server);
    expect(c.draftOf(_row(c, 1)).timeText, '');

    server.seedPendingSubmission(first, a);
    await c.refreshAfterSync();

    expect(c.draftOf(_row(c, 1)).timeText, '9:00');
    expect(c.round, 1);
    expect(c.group, 1);
  });

  test('a row with typed values keeps them and a changed official score marks '
      'it stale', () async {
    final server = ScoringServer()..seedScore(first, a);
    final c = await _open(server);
    c.draftOf(_row(c, 1)).setHeight('99');
    expect(c.isDirty(_row(c, 1)), isTrue);

    // Another operator corrected it meanwhile.
    server.seedCorrection(first, b, 'Corrected elsewhere');
    await c.refreshAfterSync();

    expect(c.draftOf(_row(c, 1)).heightText, '99');
    expect(c.saveOf(first).kind, RowSaveKind.stale);
    expect(c.theirsOf(first), isNotNull);
    expect(c.theirsOf(first)!['time_flown'], 500);
  });

  test(
    'a row with typed values and an unchanged score is left as typed',
    () async {
      final server = ScoringServer()..seedScore(first, a);
      final c = await _open(server);
      c.draftOf(_row(c, 1)).setHeight('99');

      server.seedPendingSubmission(second, b);
      await c.refreshAfterSync();

      expect(c.draftOf(_row(c, 1)).heightText, '99');
      expect(c.saveOf(first).kind, RowSaveKind.idle);
      expect(c.draftOf(_row(c, 2)).timeText, '8:20');
    },
  );

  test('a failed read leaves the page as it was', () async {
    final server = ScoringServer()..seedScore(first, a);
    final c = await _open(server);
    c.draftOf(_row(c, 1)).setHeight('99');

    server.readFailure = 503;
    await c.refreshAfterSync();

    expect(c.loadError, isNull);
    expect(c.data, isNotNull);
    expect(c.draftOf(_row(c, 1)).heightText, '99');
  });
}
