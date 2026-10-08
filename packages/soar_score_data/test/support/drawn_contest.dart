import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

/// Creates, configures and draws an F5J contest of four pilots in two rounds
/// of one group, owned by [actor].
Future<core.Id> drawnContest(Repository repository, core.Id actor) async {
  var n = 0;
  core.MutationMetadata meta() => core.MutationMetadata(
    clientMutationId: 'setup-${n++}',
    authority: core.Authority.director,
    clientTime: DateTime.utc(2026, 10, 8),
    actorId: actor,
  );
  final contestId = core.Id.create();
  await ContestsService(repository).createContest(
    NewContest(
      id: contestId,
      timezone: 'America/Denver',
      details: ContestDetails(
        name: 'Spring Open',
        startDateTime: DateTime.utc(2026, 10, 17, 14),
        endDateTime: DateTime.utc(2026, 10, 18, 22),
      ),
    ),
    ownerAccountId: actor,
    metadata: meta(),
  );
  await ContestConfigurationService(repository).save(
    contestId,
    ConfigurationInput(
      baseRevisionNumber: 0,
      disciplineProfileId: core.SystemDisciplineProfiles.f5jId,
      config: core.ContestConfig(
        core: const {},
        discipline: const {'working_time': 600},
      ),
    ),
    createdBy: actor,
    metadata: meta(),
  );
  for (var i = 0; i < 4; i++) {
    final profile = await ParticipantsService(repository).create(
      actor,
      core.Id.create(),
      ParticipantDetails(
        firstName: 'Pilot$i',
        lastName: 'Test',
        club: 'Club$i',
        faiNumber: 'FAI-$i',
        email: 'pilot$i@example.com',
      ),
      metadata: meta(),
    );
    await ParticipationsService(repository).add(
      contestId,
      actor,
      id: core.Id.create(),
      participantProfileId: profile.id,
      metadata: meta(),
    );
  }
  await MatrixService(repository).drawFirst(
    contestId,
    id: core.Id.create(),
    rounds: 2,
    groupsPerRound: 1,
    randomSeed: 7,
    actorId: actor,
    metadata: meta(),
  );
  return contestId;
}
