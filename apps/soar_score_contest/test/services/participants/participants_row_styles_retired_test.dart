import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/contest_participants/participants_controller.dart';
import 'package:soar_score_contest/services/contest_participants/participants_row_styles.dart';

import '../../support/matrix_test_support.dart';
import '../../support/participants_page_support.dart';

void main() {
  test('a retired pilot stays marked after their edits are saved', () async {
    final server = ParticipantsServer(retiredPilot: 1);
    final c = ParticipantsController(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient((request) async => server.handle(request)),
      ),
      contestId: contestId,
    );
    addTearDown(c.dispose);
    await c.load();
    final id = personParticipationId(1).value;
    var row = c.data!.participants.firstWhere((p) => p.rowId == id);
    expect(c.styleOf(row).status?.text, 'Retired from round 2');

    c.edit(row.withEdits(classification: 'Sportsman'));
    await c.save();
    row = c.data!.participants.firstWhere((p) => p.rowId == id);
    // The save worked and the row carries that outcome, yet the status still
    // says the pilot retired.
    expect(c.stateOf(id).outcome.name, 'saved');
    expect(c.styleOf(row).status?.text, 'Retired from round 2');
  });
}
