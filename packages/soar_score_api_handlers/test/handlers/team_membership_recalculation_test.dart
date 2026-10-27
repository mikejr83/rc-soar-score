import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'matrix_test_support.dart';
import 'recalculation_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = matrixTestContestId;
const _teamId = '019c0000-0000-7000-8000-0000000003f1';
const _membershipId = '019c0000-0000-7000-8000-0000000003f2';

/// A team change recalculates the results of a contest that has scores, even
/// after the draw.
void main() {
  late List<int> recalculations;

  Future<HandlerHarness> scoredContest() async {
    final api = HandlerHarness(
      _owner,
      recalculation: RecalculationService(RefusingResults(recalculations)),
    );
    await drawnContest(api);
    final slot = await assignmentOfPilot(api, 1);
    await api.send(
      'POST',
      '/contests/$_contestId/assignments/${slot['id']}/scores',
      body: {
        'client_mutation_id': 'entry-1',
        'base_score_revision': 0,
        'components': {'time_flown': 540, 'launch_height': 200},
      },
    );
    await api.send(
      'POST',
      '/contests/$_contestId/teams',
      body: {'id': _teamId, 'name': 'Gators'},
    );
    recalculations.clear();
    return api;
  }

  setUp(() => recalculations = []);

  test('a pilot joins and leaves a team after the draw', () async {
    final api = await scoredContest();

    final join = await api.send(
      'POST',
      '/contests/$_contestId/team-memberships',
      body: {
        'id': _membershipId,
        'team_id': _teamId,
        'contest_participation_id': matrixTestParticipationId(2),
      },
    );
    expect(join.statusCode, 201, reason: await api.json(join).toString());
    expect(recalculations, hasLength(1));

    final leave = await api.send(
      'DELETE',
      '/contests/$_contestId/team-memberships/$_membershipId',
    );
    expect(leave.statusCode, 204);
    expect(recalculations, hasLength(2));
  });
}
