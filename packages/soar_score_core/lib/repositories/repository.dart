import 'contest_configuration_revision_repository.dart';
import 'contest_participation_repository.dart';
import 'contest_repository.dart';
import 'participant_profile_repository.dart';
import 'team_membership_repository.dart';
import 'team_repository.dart';

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
}
