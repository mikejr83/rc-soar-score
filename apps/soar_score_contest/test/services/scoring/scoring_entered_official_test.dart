import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/scoring/scoring_completeness.dart';
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
  const flight = {'time_flown': 540, 'launch_height': 120};

  test('entered and official are counted apart', () async {
    final server = ScoringServer()
      ..seedScore(scoringAssignmentId(1, 1), flight)
      ..seedPendingSubmission(scoringAssignmentId(1, 2), flight)
      ..seedPendingSubmission(
        scoringAssignmentId(1, 3),
        flight,
        inReview: true,
      );
    final c = await _open(server);

    final official = _row(c, 1);
    expect((official.isEntered, official.isOfficial), (true, true));
    final pending = _row(c, 2);
    expect(pending.hasPendingSubmission, isTrue);
    expect((pending.isEntered, pending.isOfficial), (true, false));

    final round = c.currentRound!;
    // Group 1: one official and one waiting. Nothing is missing.
    final group = c.data!.groupCompleteness(round, 1);
    expect((group.entered, group.official, group.total), (2, 1, 2));
    expect(group.state, CompletenessState.entered);
    // Group 2: one in review, one not entered.
    final second = c.data!.groupCompleteness(round, 2);
    expect((second.entered, second.official, second.total), (1, 0, 2));
    expect(second.state, CompletenessState.partial);
    final whole = c.data!.roundCompleteness(round);
    expect((whole.entered, whole.official, whole.total), (3, 1, 4));
    // The director still has work in group 1, the first group to open.
    expect(c.data!.firstOpen, (1, 1));
  });

  test(
    'a group of only waiting submissions is entered, not official',
    () async {
      final server = ScoringServer()
        ..seedPendingSubmission(scoringAssignmentId(1, 1), flight)
        ..seedPendingSubmission(scoringAssignmentId(1, 2), flight);
      final c = await _open(server);

      final completeness = c.data!.groupCompleteness(c.currentRound!, 1);
      expect(completeness.state, CompletenessState.entered);
      expect((completeness.entered, completeness.official), (2, 0));
    },
  );
}
