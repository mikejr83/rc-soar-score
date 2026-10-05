import 'contest_configuration_revision_repository.dart';
import 'contest_participation_repository.dart';
import 'contest_repository.dart';
import 'flight_result_repository.dart';
import 'landing_table_repository.dart';
import 'matrix_assignment_repository.dart';
import 'matrix_revision_repository.dart';
import 'official_score_repository.dart';
import 'participant_profile_repository.dart';
import 'participation_standing_repository.dart';
import 'round_group_repository.dart';
import 'round_repository.dart';
import 'score_attempt_repository.dart';
import 'score_placeholder_repository.dart';
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

  TeamRepository get teamRepository;

  TeamMembershipRepository get teamMembershipRepository;

  LandingTableRepository get landingTableRepository;

  MatrixRevisionRepository get matrixRevisionRepository;

  RoundRepository get roundRepository;

  RoundGroupRepository get roundGroupRepository;

  MatrixAssignmentRepository get matrixAssignmentRepository;

  ScorePlaceholderRepository get scorePlaceholderRepository;

  ScoreAttemptRepository get scoreAttemptRepository;

  OfficialScoreRepository get officialScoreRepository;

  FlightResultRepository get flightResultRepository;

  ParticipationStandingRepository get participationStandingRepository;

  TeamStandingRepository get teamStandingRepository;
}
