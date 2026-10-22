import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import '../support/inspection_import.dart';

/// What a contest imported for inspection looks like through the embedded
/// API: browsable and editable like any contest, its rows listed with the
/// director's own, and nothing else changes for the account the app acts as.
void main() {
  late Directory dir;
  late EmbeddedServer server;
  late ApiClient client;
  late core.Contest inspected;
  late core.Id owner;
  late int pilots;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('inspection_visibility_test');
    server = await startEmbeddedServer('${dir.path}/soar_score.db');
    client = ApiClient(
      baseUrl: server.baseUrl,
      tokenProvider: () async => server.secret,
    );
    final imported = await importDemoForInspection(
      server.database,
      localAccountId: server.localAccountId,
      // A contest that is still open to changes.
      contestName: 'Mountain States Team F5J',
    );
    inspected = imported.contest;
    owner = imported.owner;
    pilots =
        (await server.repository.contestParticipationRepository.listForContest(
          inspected.id,
        )).length;
  });

  tearDown(() async {
    client.close();
    await server.close();
    dir.deleteSync(recursive: true);
  });

  CreateParticipantRequest newProfile(String name) => CreateParticipantRequest(
    id: core.Id.create(),
    firstName: name,
    lastName: 'Tester',
  );

  test('the contest is listed and opens', () async {
    expect((await client.contests()).map((c) => c.id), contains(inspected.id));
    expect((await client.contest(inspected.id)).ownerAccountId, owner);
    expect(await client.participations(inspected.id), hasLength(pilots));
  });

  test('the lists show the imported rows with the account\'s own', () async {
    final own = await client.createParticipant(newProfile('Mine'));

    final profiles = await client.participants();

    expect(own.ownerAccountId, server.localAccountId);
    expect(
      profiles.where((p) => p.ownerAccountId == owner),
      hasLength(pilots),
      reason: 'the imported pilots',
    );
    expect(profiles.map((p) => p.id), contains(own.id));
  });

  test('the lists still show them when the app acts as an account', () async {
    final account = core.Id.create();
    server.actAs(account);

    final profiles = await client.participants();

    expect(profiles.where((p) => p.ownerAccountId == owner), hasLength(pilots));
  });

  test('another owner\'s rows stay out of the lists', () async {
    final stranger = core.Id.create();
    await server.database.customStatement(
      "INSERT INTO participant_profiles (id, owner_account_id, first_name, "
      "last_name, created_at, updated_at) VALUES ('${core.Id.create().value}', "
      "'${stranger.value}', 'Not', 'Marked', '2026-01-01T00:00:00Z', "
      "'2026-01-01T00:00:00Z')",
    );

    final profiles = await client.participants();

    expect(profiles.where((p) => p.ownerAccountId == stranger), isEmpty);
  });

  test('system roles are listed once', () async {
    final roles = await client.roles();

    expect(roles.map((r) => r.id).toSet().length, roles.length);
    expect(roles.where((r) => r.isSystem), isNotEmpty);
  });

  test('an imported pilot can be edited and stays with its owner', () async {
    final pilot = (await client.participants()).firstWhere(
      (p) => p.ownerAccountId == owner,
    );

    final saved = await client.updateParticipant(
      pilot.id,
      UpdateParticipantRequest(
        baseRevision: pilot.revision,
        firstName: 'Renamed',
        lastName: pilot.lastName,
      ),
    );

    expect(saved.firstName, 'Renamed');
    expect(saved.ownerAccountId, owner);
    expect((await client.participant(pilot.id)).firstName, 'Renamed');
  });

  test('a pilot of an unmarked owner is not reachable', () async {
    final stranger = core.Id.create();
    final id = core.Id.create();
    await server.database.customStatement(
      "INSERT INTO participant_profiles (id, owner_account_id, first_name, "
      "last_name, created_at, updated_at) VALUES ('${id.value}', "
      "'${stranger.value}', 'Not', 'Marked', '2026-01-01T00:00:00Z', "
      "'2026-01-01T00:00:00Z')",
    );

    await expectLater(
      client.updateParticipant(
        id,
        UpdateParticipantRequest(
          baseRevision: 0,
          firstName: 'Hijack',
          lastName: 'Attempt',
        ),
      ),
      throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 404)),
    );
  });

  test('a pilot made for the contest can be added to it', () async {
    final profile = await client.createParticipant(
      newProfile('Newcomer'),
      forContest: inspected.id,
    );
    expect(profile.ownerAccountId, owner);

    final participation = await client.addParticipation(
      inspected.id,
      AddParticipationRequest(
        id: core.Id.create(),
        participantProfileId: profile.id,
      ),
    );

    expect(participation.participantProfileId, profile.id);
    expect(await client.participations(inspected.id), hasLength(pilots + 1));
  });

  test('a pilot of the account cannot be added to the contest', () async {
    final mine = await client.createParticipant(newProfile('Mine'));

    await expectLater(
      client.addParticipation(
        inspected.id,
        AddParticipationRequest(
          id: core.Id.create(),
          participantProfileId: mine.id,
        ),
      ),
      throwsA(isA<ApiHttpError>()),
    );
  });

  test(
    'a role made for the contest is the contest\'s and can be used',
    () async {
      final role = await client.createRole(
        CreateRoleRequest(id: core.Id.create(), displayName: 'Scorekeeper'),
        forContest: inspected.id,
      );
      expect(role.ownerAccountId, owner);
      expect((await client.roles()).map((r) => r.id), contains(role.id));

      final profile = await client.createParticipant(
        newProfile('Official'),
        forContest: inspected.id,
      );
      final participation = await client.addParticipation(
        inspected.id,
        AddParticipationRequest(
          id: core.Id.create(),
          participantProfileId: profile.id,
          roleId: role.id,
        ),
      );
      expect(participation.roleId, role.id);
    },
  );

  test('edits in the contest are made as the inspection owner', () async {
    final participation = (await client.participations(inspected.id)).first;

    await client.updateParticipation(
      inspected.id,
      participation.id,
      UpdateParticipationRequest(
        baseRevision: participation.revision,
        classification: 'Edited',
      ),
    );

    final mutations = await DriftSyncStore(server.database)
        .pendingMutations(core.ContestScopeKey(inspected.id));
    expect(mutations.last.actorId, owner);
  });

  test('without its marker the rows are out of the lists but the contest '
      'still opens', () async {
    await server.database.customStatement(
      "DELETE FROM audit_events WHERE entity_type = 'InspectionOwner'",
    );
    server.inspectionOwners.changed();

    final profiles = await client.participants();

    expect(profiles.where((p) => p.ownerAccountId == owner), isEmpty);
    expect((await client.contest(inspected.id)).id, inspected.id);
  });
}
