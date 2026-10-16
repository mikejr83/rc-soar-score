import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/server/embedded_server.dart';

/// The participant and participation routes against the real SQLite
/// repositories behind the embedded server.
void main() {
  late Directory tempDir;
  late EmbeddedServer server;
  late ApiClient client;
  late Id contestId;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('soar_score_participants');
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
  });

  tearDown(() async {
    client.close();
    await server.close();
    tempDir.deleteSync(recursive: true);
  });

  Future<ParticipantProfile> createProfile(String first) =>
      client.createParticipant(
        CreateParticipantRequest(
          id: Id.create(),
          firstName: first,
          lastName: 'Pilot',
        ),
      );

  test('profiles are owned by the Local account and can be edited', () async {
    final profile = await createProfile('Ada');

    expect(profile.ownerAccountId, server.localAccountId);
    expect(await client.participants(), [profile]);

    final updated = await client.updateParticipant(
      profile.id,
      UpdateParticipantRequest(
        baseRevision: profile.revision,
        firstName: 'Ada',
        lastName: 'Byron',
        club: 'Front Range',
      ),
    );
    expect(updated.lastName, 'Byron');
    expect(updated.revision, profile.revision + 1);
    expect(await client.participant(profile.id), updated);
  });

  test('the shipped roles can be listed', () async {
    final roles = await client.roles();

    expect(
      roles.map((role) => role.id),
      containsAll([SystemRoles.pilotId, SystemRoles.helperId]),
    );
  });

  test('a role is added, renamed, used, locked and then deleted', () async {
    final created = await client.createRole(
      CreateRoleRequest(id: Id.create(), displayName: 'Timer'),
    );
    expect(created.ownerAccountId, server.localAccountId);
    expect(await client.roles(), contains(created));

    final renamed = await client.renameRole(
      created.id,
      RenameRoleRequest(baseRevision: created.revision, displayName: 'Scorer'),
    );
    expect(renamed.displayName, 'Scorer');

    final profile = await createProfile('Ada');
    final participation = await client.addParticipation(
      contestId,
      AddParticipationRequest(
        id: Id.create(),
        participantProfileId: profile.id,
        roleId: renamed.id,
      ),
    );
    final usage = await client.roleUsage(renamed.id);
    expect(usage.single.contestName, 'Spring Open');
    expect(usage.single.participantCount, 1);
    await expectLater(
      client.deleteRole(renamed.id),
      throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 409)),
    );

    await client.removeParticipation(contestId, participation.id);
    await client.deleteRole(renamed.id);
    expect(await client.roles(), isNot(contains(renamed)));
  });

  test('a participant joins a contest, is changed and is removed', () async {
    final profile = await createProfile('Ada');

    final pilot = await client.addParticipation(
      contestId,
      AddParticipationRequest(
        id: Id.create(),
        participantProfileId: profile.id,
      ),
    );
    expect(pilot.roleType, RoleType.pilot);
    expect(await client.participations(contestId), [pilot]);

    final retired = await client.updateParticipation(
      contestId,
      pilot.id,
      UpdateParticipationRequest(
        baseRevision: pilot.revision,
        classification: 'Expert',
        retiredAtRound: 2,
      ),
    );
    expect(retired.retiredAtRound, 2);
    expect(retired.classification, 'Expert');

    // The profile is part of the contest, so it cannot be deleted yet.
    await expectLater(
      client.deleteParticipant(profile.id),
      throwsA(
        isA<ApiHttpError>().having((e) => e.statusCode, 'statusCode', 409),
      ),
    );

    await client.removeParticipation(contestId, pilot.id);
    expect(await client.participations(contestId), isEmpty);
    await client.deleteParticipant(profile.id);
    expect(await client.participants(), isEmpty);
  });

  test('a profile joins a contest once', () async {
    final profile = await createProfile('Ada');
    await client.addParticipation(
      contestId,
      AddParticipationRequest(
        id: Id.create(),
        participantProfileId: profile.id,
      ),
    );

    await expectLater(
      client.addParticipation(
        contestId,
        AddParticipationRequest(
          id: Id.create(),
          participantProfileId: profile.id,
        ),
      ),
      throwsA(
        isA<ApiHttpError>().having((e) => e.statusCode, 'statusCode', 409),
      ),
    );
  });
}
