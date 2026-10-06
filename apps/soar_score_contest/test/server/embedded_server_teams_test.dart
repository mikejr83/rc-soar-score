import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/server/embedded_server.dart';

/// The team routes against the real SQLite repositories behind the embedded
/// server.
void main() {
  late Directory tempDir;
  late EmbeddedServer server;
  late ApiClient client;
  late Id contestId;
  late ContestParticipation pilot;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('soar_score_teams');
    server = await startEmbeddedServer('${tempDir.path}/soar_score.db');
    client = ApiClient(baseUrl: server.baseUrl);
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
    final profile = await client.createParticipant(
      CreateParticipantRequest(
        id: Id.create(),
        firstName: 'Ada',
        lastName: 'Pilot',
      ),
    );
    pilot = await client.addParticipation(
      contestId,
      AddParticipationRequest(
        id: Id.create(),
        participantProfileId: profile.id,
      ),
    );
  });

  tearDown(() async {
    client.close();
    await server.close();
    tempDir.deleteSync(recursive: true);
  });

  Matcher conflict() => throwsA(
    isA<ApiHttpError>().having((e) => e.statusCode, 'statusCode', 409),
  );

  test('a team is created, renamed and listed by name', () async {
    final red = await client.createTeam(
      contestId,
      CreateTeamRequest(id: Id.create(), name: 'Team Red'),
    );
    final blue = await client.createTeam(
      contestId,
      CreateTeamRequest(id: Id.create(), name: 'Team Blue'),
    );

    final renamed = await client.updateTeam(
      contestId,
      red.id,
      UpdateTeamRequest(baseRevision: red.revision, name: 'Team Crimson'),
    );

    expect(renamed.name, 'Team Crimson');
    expect(await client.teams(contestId), [blue, renamed]);
  });

  test('a team name is used once per contest', () async {
    await client.createTeam(
      contestId,
      CreateTeamRequest(id: Id.create(), name: 'Team Red'),
    );

    await expectLater(
      client.createTeam(
        contestId,
        CreateTeamRequest(id: Id.create(), name: 'Team Red'),
      ),
      conflict(),
    );
  });

  test('a participant is on one team, and leaves with its team', () async {
    final red = await client.createTeam(
      contestId,
      CreateTeamRequest(id: Id.create(), name: 'Team Red'),
    );
    final blue = await client.createTeam(
      contestId,
      CreateTeamRequest(id: Id.create(), name: 'Team Blue'),
    );
    final member = await client.addTeamMember(
      contestId,
      AddTeamMemberRequest(
        id: Id.create(),
        teamId: red.id,
        contestParticipationId: pilot.id,
      ),
    );
    expect(await client.teamMemberships(contestId), [member]);

    await expectLater(
      client.addTeamMember(
        contestId,
        AddTeamMemberRequest(
          id: Id.create(),
          teamId: blue.id,
          contestParticipationId: pilot.id,
        ),
      ),
      conflict(),
    );

    await client.deleteTeam(contestId, red.id);
    expect(await client.teamMemberships(contestId), isEmpty);
    expect(await client.teams(contestId), [blue]);
  });
}
