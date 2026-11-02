import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/scoring/row_save.dart';
import 'package:soar_score_contest/services/scoring/scoring_controller.dart';

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
  for (final row in c.rows.take(2)) {
    c.draftOf(row)
      ..setTime('540')
      ..setHeight('180');
  }
  return c;
}

void main() {
  test(
    'an already_stored row is reloaded and its next save has a new id',
    () async {
      final server = ScoringServer();
      final first = scoringAssignmentId(1, 1);
      server.entryFailures[first] = (409, 'already_stored');
      final c = await _open(server);

      expect(await c.saveAll(), 1);
      expect(c.saveOf(first).kind, RowSaveKind.stale);
      final firstId = server.entries.firstWhere(
        (e) => e['assignment_id'] == first.value,
      )['client_mutation_id'];

      server.entryFailures.clear();
      await c.keepMine(c.rows.firstWhere((r) => r.id == first));

      expect(server.entries.last['client_mutation_id'], isNot(firstId));
    },
  );

  test('the recalculation warning of the bulk answer is kept', () async {
    final server = ScoringServer()..bulkWarning = 'The results are stale.';
    final c = await _open(server);

    expect(await c.saveAll(), 2);

    expect(c.recalculationWarning, 'The results are stale.');
    expect(server.entryRequests, 1);
  });

  test('a server without the bulk route gets one request per row', () async {
    final server = ScoringServer()..bulkStatus = 404;
    final c = await _open(server);

    expect(await c.saveAll(), 2);

    // One refused bulk request, then each row on its own.
    expect(server.entryRequests, 3);
    expect(server.entries, hasLength(2));
  });
}
