import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart'
    show ContestConfig, Id, SystemDisciplineProfiles, SystemRoles;

/// Creates a contest of seven pilots in three teams through [client], with
/// teams, team protection, pilot numbers and lanes on, and returns its id.
Future<Id> seedMatrixContest(ApiClient client) async {
  final contestId = Id.create();
  await client.createContest(
    CreateContestRequest(
      id: contestId,
      name: 'Seeded Open',
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
      config: ContestConfig(
        core: {
          'lane_mode': 'Random',
          'participant_numbers_enabled': true,
          'teams_enabled': true,
          'team_pilot_count': 3,
          'team_protection': true,
        },
        discipline: {'working_time': 600},
      ),
    ),
  );
  final teams = [
    for (final name in ['Flying Gators', 'Harbor Hawks', 'Lake Wings'])
      await client.createTeam(
        contestId,
        CreateTeamRequest(id: Id.create(), name: name),
      ),
  ];
  for (var n = 0; n < 7; n++) {
    final profile = await client.createParticipant(
      CreateParticipantRequest(
        id: Id.create(),
        firstName: 'Pilot',
        lastName: 'Number${n + 1}',
      ),
    );
    final participation = await client.addParticipation(
      contestId,
      AddParticipationRequest(
        id: Id.create(),
        participantProfileId: profile.id,
        roleId: SystemRoles.pilotId,
      ),
    );
    await client.addTeamMember(
      contestId,
      AddTeamMemberRequest(
        id: Id.create(),
        teamId: teams[n % 3].id,
        contestParticipationId: participation.id,
      ),
    );
  }

  return contestId;
}
