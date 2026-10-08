import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_contest/services/matrix/fairness_view.dart';
import 'package:soar_score_contest/services/matrix/matrix_grid_model.dart';
import 'package:soar_score_contest/services/matrix/matrix_page_data.dart';
import 'package:soar_score_core/soar_score_core.dart' show Id;

import '../support/embedded_matrix_support.dart';

/// The matrix page's data path against the real embedded API and a real
/// SQLite database: a contest of seven pilots in three teams is set up and
/// drawn through the same client the page uses.
void main() {
  late Directory tempDir;
  late EmbeddedServer server;
  late ApiClient client;
  late Id contestId;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('soar_score_matrix_flow');
    server = await startEmbeddedServer(
      '${tempDir.path}${Platform.pathSeparator}soar_score.db',
    );
    client = ApiClient(baseUrl: server.baseUrl);
    contestId = await seedMatrixContest(client);
  });

  tearDown(() async {
    client.close();
    await server.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'draws a matrix with every pilot once per round, and reloads it',
    () async {
      final before = await MatrixPageData.load(client, contestId);
      expect(before.matrix.isEmpty, isTrue);
      expect(before.scoringPilots, 7);
      expect(before.showNumbers, isTrue);
      expect(before.showTeams, isTrue);
      expect(before.largestTeam, 3);

      final request = DrawMatrixRequest(
        id: Id.create(),
        rounds: 4,
        groupsPerRound: 3,
        randomSeed: 42,
      );
      final drawn = await client.drawMatrix(contestId, request);
      expect(drawn.revision, isNotNull);

      // Repeating the same request returns the matrix it drew.
      final again = await client.drawMatrix(contestId, request);
      expect(again.revision?.id, drawn.revision?.id);

      final after = await MatrixPageData.load(client, contestId);
      expect(after.matrix.revision?.id, drawn.revision?.id);
      expect(after.matrix.revision?.randomSeed, 42);

      final model = MatrixGridModel.of(after.matrix, after.pilots);
      expect(model.rounds, hasLength(4));
      expect(model.groupCount, 3);
      expect(model.hasLanes, isTrue);
      expect(model.pilots, hasLength(7));
      for (final round in model.rounds) {
        expect(round.pilotCount, 7);
        expect(round.distinctPilots, 7);
        expect(round.groups.map((group) => group.length).toList()..sort(), [
          2,
          2,
          3,
        ]);
      }
      // The draw assigned pilot numbers, and the page shows them.
      expect(model.pilots.every((pilot) => pilot.number != null), isTrue);
      expect(model.pilots.map((pilot) => pilot.number).toSet(), hasLength(7));
      // Team protection: no teammates in a group.
      for (final round in model.rounds) {
        for (final group in round.groups) {
          final teams = group.map((slot) => slot.pilot.teamId).toList();
          expect(teams.toSet(), hasLength(teams.length));
        }
      }

      final fairness = FairnessView.of(after.matrix.revision?.fairnessSummary);
      expect(fairness.score, inInclusiveRange(0, 100));
      expect(fairness.unmet, isNotNull);
      expect(fairness.maxRepeats, isNotNull);
      expect(
        fairness.bars.fold<int>(0, (sum, bar) => sum + bar.$2),
        greaterThan(0),
      );
    },
  );

  test('a second draw is refused with a 409', () async {
    await client.drawMatrix(
      contestId,
      DrawMatrixRequest(id: Id.create(), rounds: 2, groupsPerRound: 3),
    );
    await expectLater(
      client.drawMatrix(
        contestId,
        DrawMatrixRequest(id: Id.create(), rounds: 2, groupsPerRound: 3),
      ),
      throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 409)),
    );
  });

  test('settings the draw cannot meet are refused with a 400', () async {
    // Team protection needs at least 3 groups for teams of 3.
    await expectLater(
      client.drawMatrix(
        contestId,
        DrawMatrixRequest(id: Id.create(), rounds: 2, groupsPerRound: 2),
      ),
      throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 400)),
    );
    final data = await MatrixPageData.load(client, contestId);
    expect(data.matrix.isEmpty, isTrue);
  });
}
