import 'account_alias_repository.dart';
import 'account_identity_repository.dart';
import 'contest_model_link_repository.dart';
import 'contest_configuration_preset_repository.dart';
import 'model_catalog_repository.dart';
import 'account_public_profile_repository.dart';
import 'account_repository.dart';
import 'contest_configuration_revision_repository.dart';
import 'contest_participation_repository.dart';
import 'contest_repository.dart';
import 'delist_request_repository.dart';
import 'discipline_profile_repository.dart';
import 'flight_result_repository.dart';
import 'installation_activation_repository.dart';
import 'installation_repository.dart';
import 'invitation_repository.dart';
import 'landing_table_repository.dart';
import 'matrix_assignment_repository.dart';
import 'matrix_revision_repository.dart';
import 'official_score_repository.dart';
import 'participant_account_link_repository.dart';
import 'participant_directory_entry_repository.dart';
import 'participant_profile_repository.dart';
import 'participation_standing_repository.dart';
import 'audit_event_repository.dart';
import 'publication_identity_repository.dart';
import 'publication_participant_repository.dart';
import 'publication_projection_repository.dart';
import 'publication_publisher.dart';
import 're_flight_participant_repository.dart';
import 're_flight_repository.dart';
import 'results_repository.dart';
import 'role_repository.dart';
import 'round_group_repository.dart';
import 'round_repository.dart';
import 'score_attempt_repository.dart';
import 'review_request_repository.dart';
import 'score_placeholder_repository.dart';
import 'sync_cursor_repository.dart';
import 'team_membership_repository.dart';
import 'team_repository.dart';
import 'team_standing_repository.dart';

/// The persistence contracts an application uses.
///
/// Callers depend on these and never on how they are stored.
abstract interface class Repository {
  ContestRepository get contestRepository;

  ContestConfigurationRevisionRepository
  get contestConfigurationRevisionRepository;

  ParticipantProfileRepository get participantProfileRepository;

  ContestParticipationRepository get contestParticipationRepository;

  RoleRepository get roleRepository;

  TeamRepository get teamRepository;

  TeamMembershipRepository get teamMembershipRepository;

  LandingTableRepository get landingTableRepository;

  DisciplineProfileRepository get disciplineProfileRepository;

  MatrixRevisionRepository get matrixRevisionRepository;

  RoundRepository get roundRepository;

  RoundGroupRepository get roundGroupRepository;

  MatrixAssignmentRepository get matrixAssignmentRepository;

  ReFlightRepository get reFlightRepository;

  ReFlightParticipantRepository get reFlightParticipantRepository;

  ScorePlaceholderRepository get scorePlaceholderRepository;

  ReviewRequestRepository get reviewRequestRepository;

  ScoreAttemptRepository get scoreAttemptRepository;

  OfficialScoreRepository get officialScoreRepository;

  FlightResultRepository get flightResultRepository;

  ParticipationStandingRepository get participationStandingRepository;

  TeamStandingRepository get teamStandingRepository;

  ResultsRepository get resultsRepository;

  AuditEventRepository get auditEventRepository;

  PublicationIdentityRepository get publicationIdentityRepository;

  PublicationProjectionRepository get publicationProjectionRepository;

  PublicationParticipantRepository get publicationParticipantRepository;

  PublicationPublisher get publicationPublisher;

  DelistRequestRepository get delistRequestRepository;

  AccountRepository get accountRepository;

  AccountAliasRepository get accountAliasRepository;

  AccountIdentityRepository get accountIdentityRepository;

  AccountPublicProfileRepository get accountPublicProfileRepository;

  ParticipantAccountLinkRepository get participantAccountLinkRepository;

  ParticipantDirectoryEntryRepository get participantDirectoryEntryRepository;

  InstallationRepository get installationRepository;

  InstallationActivationRepository get installationActivationRepository;

  SyncCursorRepository get syncCursorRepository;

  InvitationRepository get invitationRepository;
  ModelCatalogRepository get modelCatalogRepository;

  ContestConfigurationPresetRepository get contestConfigurationPresetRepository;

  ContestModelLinkRepository get contestModelLinkRepository;
}
