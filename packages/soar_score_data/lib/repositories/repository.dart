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
      ),
      landingTableRepository = LandingTableRepository(database, stores: stores),
      matrixRevisionRepository = MatrixRevisionRepository(
        database,
        stores: stores,
      ),
      roundRepository = RoundRepository(database, stores: stores),
      roundGroupRepository = RoundGroupRepository(database, stores: stores),
      matrixAssignmentRepository = MatrixAssignmentRepository(
        database,
        stores: stores,
      ),
      scorePlaceholderRepository = ScorePlaceholderRepository(
        database,
        stores: stores,
      ),
      scoreAttemptRepository = ScoreAttemptRepository(database, stores: stores),
      officialScoreRepository = OfficialScoreRepository(
        database,
        stores: stores,
      ),
      flightResultRepository = FlightResultRepository(database, stores: stores),
      participationStandingRepository = ParticipationStandingRepository(
        database,
        stores: stores,
      ),
      teamStandingRepository = TeamStandingRepository(database, stores: stores);

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

  @override
  final core.LandingTableRepository landingTableRepository;

  @override
  final core.MatrixRevisionRepository matrixRevisionRepository;

  @override
  final core.RoundRepository roundRepository;

  @override
  final core.RoundGroupRepository roundGroupRepository;

  @override
  final core.MatrixAssignmentRepository matrixAssignmentRepository;

  @override
  final core.ScorePlaceholderRepository scorePlaceholderRepository;

  @override
  final core.ScoreAttemptRepository scoreAttemptRepository;

  @override
  final core.OfficialScoreRepository officialScoreRepository;

  @override
  final core.FlightResultRepository flightResultRepository;

  @override
  final core.ParticipationStandingRepository participationStandingRepository;

  @override
  final core.TeamStandingRepository teamStandingRepository;
}

Repository createRepository(SoarScoreDatabase database) => Repository(database);
