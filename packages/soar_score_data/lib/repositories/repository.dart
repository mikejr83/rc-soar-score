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
      roleRepository = RoleRepository(database, stores: stores),
      teamRepository = TeamRepository(database, stores: stores),
      teamMembershipRepository = TeamMembershipRepository(
        database,
        stores: stores,
      ),
      landingTableRepository = LandingTableRepository(database, stores: stores),
      disciplineProfileRepository = DisciplineProfileRepository(
        database,
        stores: stores,
      ),
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
      reFlightRepository = ReFlightRepository(database, stores: stores),
      reFlightParticipantRepository = ReFlightParticipantRepository(
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
      teamStandingRepository = TeamStandingRepository(database, stores: stores),
      auditEventRepository = AuditEventRepository(database, stores: stores),
      publicationIdentityRepository = PublicationIdentityRepository(
        database,
        stores: stores,
      ),
      publicationProjectionRepository = PublicationProjectionRepository(
        database,
        stores: stores,
      ),
      publicationParticipantRepository = PublicationParticipantRepository(
        database,
        stores: stores,
      ),
      publicationPublisher = PublicationPublisher(database, stores: stores),
      delistRequestRepository = DelistRequestRepository(
        database,
        stores: stores,
      ),
      accountRepository = AccountRepository(database, stores: stores),
      accountIdentityRepository = AccountIdentityRepository(
        database,
        stores: stores,
      ),
      accountPublicProfileRepository = AccountPublicProfileRepository(
        database,
        stores: stores,
      ),
      participantAccountLinkRepository = ParticipantAccountLinkRepository(
        database,
        stores: stores,
      ),
      participantDirectoryEntryRepository = ParticipantDirectoryEntryRepository(
        database,
        stores: stores,
      ),
      installationRepository = InstallationRepository(database, stores: stores),
      installationActivationRepository = InstallationActivationRepository(
        database,
        stores: stores,
      ),
      syncCursorRepository = SyncCursorRepository(database, stores: stores),
      invitationRepository = InvitationRepository(database, stores: stores),
      modelCatalogRepository = ModelCatalogRepository(database, stores: stores),
      contestConfigurationPresetRepository =
          ContestConfigurationPresetRepository(database, stores: stores),
      contestModelLinkRepository = ContestModelLinkRepository(
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
  final core.RoleRepository roleRepository;

  @override
  final core.TeamRepository teamRepository;

  @override
  final core.TeamMembershipRepository teamMembershipRepository;

  @override
  final core.LandingTableRepository landingTableRepository;

  @override
  final core.DisciplineProfileRepository disciplineProfileRepository;

  @override
  final core.MatrixRevisionRepository matrixRevisionRepository;

  @override
  final core.RoundRepository roundRepository;

  @override
  final core.RoundGroupRepository roundGroupRepository;

  @override
  final core.MatrixAssignmentRepository matrixAssignmentRepository;

  @override
  final core.ReFlightRepository reFlightRepository;

  @override
  final core.ReFlightParticipantRepository reFlightParticipantRepository;

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

  @override
  final core.AuditEventRepository auditEventRepository;

  @override
  final core.PublicationIdentityRepository publicationIdentityRepository;

  @override
  final core.PublicationProjectionRepository publicationProjectionRepository;

  @override
  final core.PublicationParticipantRepository publicationParticipantRepository;

  @override
  final core.PublicationPublisher publicationPublisher;

  @override
  final core.DelistRequestRepository delistRequestRepository;

  @override
  final core.AccountRepository accountRepository;

  @override
  final core.AccountIdentityRepository accountIdentityRepository;

  @override
  final core.AccountPublicProfileRepository accountPublicProfileRepository;

  @override
  final core.ParticipantAccountLinkRepository participantAccountLinkRepository;

  @override
  final core.ParticipantDirectoryEntryRepository
  participantDirectoryEntryRepository;

  @override
  final core.InstallationRepository installationRepository;

  @override
  final core.InstallationActivationRepository installationActivationRepository;

  @override
  final core.SyncCursorRepository syncCursorRepository;

  final core.InvitationRepository invitationRepository;

  @override
  final core.ModelCatalogRepository modelCatalogRepository;

  @override
  final core.ContestConfigurationPresetRepository
  contestConfigurationPresetRepository;

  @override
  final core.ContestModelLinkRepository contestModelLinkRepository;
}

Repository createRepository(SoarScoreDatabase database) => Repository(database);
