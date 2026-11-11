import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/contest_participants/participants_controller.dart';
import 'package:soar_score_contest/services/contest_participants/stored_participant.dart';
import 'package:soar_score_contest/services/participants/participant_row_style.dart';

import '../../support/matrix_test_support.dart';
import '../../support/participants_page_support.dart';

void main() {
  test(
    'a sync that arrives during a save reads the list once it ends',
    () async {
      final server = ParticipantsServer();
      final gate = Completer<void>();
      var hold = false;
      final c = ParticipantsController(
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost'),
          httpClient: MockClient((request) async {
            if (hold && request.method == 'PUT') await gate.future;
            return server.handle(request);
          }),
        ),
        contestId: contestId,
      );
      addTearDown(c.dispose);
      await c.load();
      final row = c.data!.participants.firstWhere(
        (p) => p.rowId == personParticipationId(1).value,
      );
      c.edit(row.withEdits(classification: 'Sportsman'));

      hold = true;
      final saving = c.save();
      await Future<void>.delayed(Duration.zero);
      expect(c.saving, isTrue);

      // Person 2 changed on another device while the save runs.
      server.changeElsewhere(2);
      await c.refreshQuietly();
      hold = false;
      gate.complete();
      await saving;
      await Future<void>.delayed(Duration.zero);

      final two = c.data!.participants.firstWhere(
        (p) => p.rowId == personParticipationId(2).value,
      );
      expect(two.classification, 'Expert');
    },
  );

  test(
    'a save that starts while a refresh read is out is not rolled back',
    () async {
      final server = ParticipantsServer();
      final gate = Completer<void>();
      var hold = false;
      final c = ParticipantsController(
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost'),
          httpClient: MockClient((request) async {
            // The answer is taken now, so it is the old list when it arrives.
            final answer = await server.handle(request);
            if (hold && request.method == 'GET') await gate.future;
            return answer;
          }),
        ),
        contestId: contestId,
      );
      addTearDown(c.dispose);
      await c.load();
      final id = personParticipationId(1).value;
      c.edit(
        c.data!.participants
            .firstWhere((p) => p.rowId == id)
            .withEdits(classification: 'Sportsman'),
      );

      hold = true;
      final refresh = c.refreshQuietly();
      await Future<void>.delayed(Duration.zero);
      hold = false;
      await c.save();
      gate.complete();
      await refresh;

      expect(c.hasUnsaved, isFalse);
      expect(
        c.data!.participants.firstWhere((p) => p.rowId == id).classification,
        'Sportsman',
      );
    },
  );

  test('a later sync is not lost behind a read that is still out', () async {
    final server = ParticipantsServer();
    final gate = Completer<void>();
    var hold = false;
    var reads = 0;
    final c = ParticipantsController(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient((request) async {
          final answer = await server.handle(request);
          if (request.method == 'GET') reads++;
          if (hold && request.method == 'GET') await gate.future;
          return answer;
        }),
      ),
      contestId: contestId,
    );
    addTearDown(c.dispose);
    await c.load();

    hold = true;
    final first = c.refreshQuietly(); // reads the list as it is now
    await Future<void>.delayed(Duration.zero);
    hold = false;
    server.changeElsewhere(2);
    final during = reads;
    final second = c.refreshQuietly(); // joins behind the first
    await Future<void>.delayed(Duration.zero);
    expect(reads, during, reason: 'no second read runs beside the first');
    gate.complete();
    await Future.wait([first, second]);

    final two = c.data!.participants.firstWhere(
      (p) => p.rowId == personParticipationId(2).value,
    );
    expect(two.classification, 'Expert');
  });

  test('a refresh keeps only the cells that were edited', () async {
    final server = ParticipantsServer();
    final c = ParticipantsController(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(server.handle),
      ),
      contestId: contestId,
    );
    addTearDown(c.dispose);
    await c.load();
    final id = personParticipationId(1).value;
    StoredParticipant row() =>
        c.data!.participants.firstWhere((p) => p.rowId == id);
    c.edit(row().withEdits(classification: 'Sportsman'));

    server.changeTeamElsewhere(1, 'Harbor Hawks');
    await c.refreshQuietly();

    expect(c.cellsChanged(id), {ParticipantCell.classification});
    final shown = c.rows.firstWhere((p) => p.rowId == id);
    expect(shown.team, 'Harbor Hawks');
    expect(shown.classification, 'Sportsman');
  });

  test('a sync that arrives while the page loads is read afterwards', () async {
    final server = ParticipantsServer();
    final gate = Completer<void>();
    var hold = true;
    final c = ParticipantsController(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient((request) async {
          final answer = await server.handle(request);
          if (hold && request.method == 'GET') await gate.future;
          return answer;
        }),
      ),
      contestId: contestId,
    );
    addTearDown(c.dispose);
    final loading = c.load(); // reads the list as it is now
    await Future<void>.delayed(Duration.zero);
    hold = false;
    server.changeElsewhere(2);
    await c.refreshQuietly();
    gate.complete();
    await loading;

    final two = c.data!.participants.firstWhere(
      (p) => p.rowId == personParticipationId(2).value,
    );
    expect(two.classification, 'Expert');
  });
}
