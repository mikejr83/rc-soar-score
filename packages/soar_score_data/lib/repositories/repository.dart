import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

/// The Drift-backed repositories, built on one database.
class Repository implements core.Repository {
  Repository(SoarScoreDatabase database)
    : this._(database, EntityStores.forDatabase(database));

  Repository._(SoarScoreDatabase database, EntityStores stores)
    : contestRepository = ContestRepository(database),
      contestConfigurationRevisionRepository =
          ContestConfigurationRevisionRepository(database, stores: stores),
      participantProfileRepository = ParticipantProfileRepository(
        database,
        stores: stores,
      ),
      contestParticipationRepository = ContestParticipationRepository(
        database,
        stores: stores,
      ),
      teamRepository = TeamRepository(database, stores: stores),
      teamMembershipRepository = TeamMembershipRepository(
        database,
        stores: stores,
      );

  @override
  final core.ContestRepository contestRepository;

  @override
  final core.ContestConfigurationRevisionRepository
  contestConfigurationRevisionRepository;

  @override
  final core.ParticipantProfileRepository participantProfileRepository;

  @override
  final core.ContestParticipationRepository contestParticipationRepository;

  @override
  final core.TeamRepository teamRepository;

  @override
  final core.TeamMembershipRepository teamMembershipRepository;
}

Repository createRepository(SoarScoreDatabase database) => Repository(database);
