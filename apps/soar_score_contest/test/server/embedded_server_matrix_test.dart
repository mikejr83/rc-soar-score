import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// The matrix routes against the real SQLite repositories behind the embedded
/// server.
void main() {
  late Directory tempDir;
  late EmbeddedServer server;
  late ApiClient client;
  late Id contestId;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('soar_score_matrix');
    server = await startEmbeddedServer('${tempDir.path}/soar_score.db');
    client = ApiClient(
      baseUrl: server.baseUrl,
      tokenProvider: () async => server.secret,
    );
    contestId = Id.create();
    await client.createContest(
      CreateContestRequest(
        id: contestId,
        name: 'Spring Open',
        startDateTime: DateTime.utc(2026, 10, 17, 14),
        endDateTime: DateTime.utc(2026, 10, 18, 22),
        timezone: 'America/Denver',
      ),
    );
    await client.saveConfiguration(
      contestId,
      SaveConfigurationRequest(
        baseRevisionNumber: 0,
        disciplineProfileId: SystemDisciplineProfiles.f5jId,
        config: ContestConfig(core: {}, discipline: {'working_time': 600}),
      ),
    );
    for (var n = 1; n <= 5; n++) {
      final profile = await client.createParticipant(
        CreateParticipantRequest(
          id: Id.create(),
          firstName: 'Pilot$n',
          lastName: 'Test',
        ),
      );
      await client.addParticipation(
        contestId,
        AddParticipationRequest(
          id: Id.create(),
          participantProfileId: profile.id,
        ),
      );
    }
  });

  tearDown(() async {
    client.close();
    await server.close();
    tempDir.deleteSync(recursive: true);
  });

  test(
    'the first draw is stored, readies the contest and numbers pilots',
    () async {
      expect((await client.matrix(contestId)).isEmpty, isTrue);

      final drawn = await client.drawMatrix(
        contestId,
        DrawMatrixRequest(
          id: Id.create(),
          rounds: 4,
          groupsPerRound: 2,
          randomSeed: 9,
        ),
      );

      expect(drawn.rounds, hasLength(4));
      expect(drawn.groups, hasLength(8));
      expect(drawn.assignments, hasLength(20));
      expect(await client.matrix(contestId), drawn);
      expect(
        (await client.contest(contestId)).lifecycleState,
        LifecycleState.ready,
      );
      final numbers = [
        for (final p in await client.participations(contestId))
          p.participantNumber,
      ];
      expect(numbers.toSet(), {1, 2, 3, 4, 5});
    },
  );

  test('a second draw is a conflict', () async {
    await client.drawMatrix(
      contestId,
      DrawMatrixRequest(id: Id.create(), rounds: 2, groupsPerRound: 1),
    );

    await expectLater(
      client.drawMatrix(
        contestId,
        DrawMatrixRequest(id: Id.create(), rounds: 2, groupsPerRound: 1),
      ),
      throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 409)),
    );
  });
}
