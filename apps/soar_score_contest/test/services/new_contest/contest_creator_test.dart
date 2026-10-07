import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_contest/services/new_contest/contest_creator.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/draft_participant.dart';
import 'package:soar_score_contest/services/new_contest/draw_settings.dart';
import 'package:soar_score_contest/services/new_contest/participant_option.dart';
import 'package:soar_score_contest/services/new_contest/scoring_settings.dart';
import 'package:soar_score_contest/services/new_contest/wizard_discipline.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Creating a contest from a draft against the real SQLite repositories and
/// handlers behind the embedded server.
void main() {
  late Directory tempDir;
  late EmbeddedServer server;
  late ApiClient client;
  late List<ParticipantProfile> profiles;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('soar_score_create');
    server = await startEmbeddedServer('${tempDir.path}/soar_score.db');
    client = ApiClient(baseUrl: server.baseUrl);
    profiles = [
      for (final (first, last) in [
        ('Mike', 'Gardner'),
        ('Sarah', 'Albright'),
        ('Ana', 'Ruiz'),
      ])
        await client.createParticipant(
          CreateParticipantRequest(
            id: Id.create(),
            firstName: first,
            lastName: last,
          ),
        ),
    ];
  });

  tearDown(() async {
    client.close();
    await server.close();
    tempDir.deleteSync(recursive: true);
  });

  ContestDraft draft({
    WizardDiscipline discipline = WizardDiscipline.f5j,
    DrawSettings draw = const DrawSettings(),
    ScoringSettings? scoring,
  }) => ContestDraft(
    name: 'Gator Cup F5J',
    venue: 'Hague Field',
    startDate: 'Nov 14, 2026',
    endDate: 'Nov 15, 2026',
    city: 'Gainesville',
    timeZone: 'America/New_York',
    discipline: discipline,
    options: const {
      ParticipantOption.teams,
      ParticipantOption.classes,
      ParticipantOption.roles,
    },
    teamPilotCount: '2',
    scoring: scoring,
    draw: draw,
    participants: [
      DraftParticipant.fromProfile(profiles[0])
          .copyWith(classification: 'open', team: 'Flying Gators'),
      DraftParticipant.fromProfile(profiles[1])
          .copyWith(classification: 'Sportsman', team: 'Flying Gators'),
      DraftParticipant.fromProfile(profiles[2])
          .copyWith(role: SystemRoles.helper, team: 'Flying Gators'),
    ],
  );

  test('creates a Configuring contest with its configuration, participants '
      'and teams', () async {
    final contest = await ContestCreator(client).create(draft(), CreationIds());

    expect(contest.name, 'Gator Cup F5J');
    expect(contest.host, 'Hague Field');
    expect(contest.timezone, 'America/New_York');
    expect(contest.lifecycleState, LifecycleState.configuring);
    expect(contest.startDateTime, DateTime.utc(2026, 11, 14, 12));

    final configuration = await client.configuration(contest.id);
    expect(configuration.disciplineProfileId, SystemDisciplineProfiles.f5jId);
    final core = configuration.config.coreOptions;
    expect(core.teamsEnabled, isTrue);
    expect(core.teamPilotCount, 2);
    expect(core.classesEnabled, isTrue);
    expect(core.rolesEnabled, isTrue);
    expect(core.dropAfterRounds, [6]);
    expect(configuration.config.discipline['working_time'], 600);

    final participations = await client.participations(contest.id);
    expect(participations, hasLength(3));
    expect(
      participations.map((p) => p.classification),
      containsAll(['Open', 'Sportsman', null]),
    );
    expect(
      participations.where((p) => p.roleType == RoleType.nonFlier),
      hasLength(1),
    );

    final teams = await client.teams(contest.id);
    expect(teams.single.name, 'Flying Gators');
    // The helper belongs to the team too.
    expect(await client.teamMemberships(contest.id), hasLength(3));
  });

  test('retrying with the same ids creates nothing twice', () async {
    final ids = CreationIds();
    final creator = ContestCreator(client);
    await creator.create(draft(), ids);
    final again = await creator.create(draft(), ids);

    expect(await client.contests(), hasLength(1));
    expect(await client.configurationRevisions(again.id), hasLength(1));
    expect(await client.participations(again.id), hasLength(3));
    expect(await client.teams(again.id), hasLength(1));
    expect(await client.teamMemberships(again.id), hasLength(3));
  });

  test('a seeded ALES draw keeps its seeded and planned rounds', () async {
    final contest = await ContestCreator(client).create(
      draft(
        discipline: WizardDiscipline.ales,
        draw: const DrawSettings(
          drawMode: DrawMode.seededManOnMan,
          seededRounds: '2',
          rounds: '9',
          laneMode: LaneMode.random,
        ),
        scoring: ScoringSettings.defaultsFor(
          WizardDiscipline.ales,
        ).copyWith(dropPolicy: DropPolicy.two, firstDrop: '4', secondDrop: '8'),
      ),
      CreationIds(),
    );

    final core = (await client.configuration(contest.id)).config.coreOptions;
    expect(core.drawMode, DrawMode.seededManOnMan);
    expect(core.preliminaryRounds, 2);
    expect(core.intendedTotalRounds, 9);
    expect(core.laneMode, LaneMode.random);
    expect(core.groupScoreMode, GroupScoreMode.time);
    expect(core.dropAfterRounds, [4, 8]);
    expect(core.teamProtection, isFalse);
  });
}
