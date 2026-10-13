import 'package:soar_score_core/soar_score_core.dart' as core;

import 'stub_account_repositories.dart';
import 'stub_configuration_repositories.dart';
import 'stub_contest_repository.dart';
import 'stub_matrix_repositories.dart';
import 'stub_participant_repositories.dart';
import 'stub_result_repositories.dart';
import 'stub_score_repositories.dart';
import 'stub_team_repositories.dart';

/// A repository with only the contracts the handlers under test use: the
/// contests, and (for configuration) its revisions, the system discipline
/// profiles and the system landing tables.
class StubRepository implements core.Repository {
  StubRepository(this._contestRepository)
    : configurations = StubConfigurationRevisionRepository(
        _contestRepository is StubContestRepository
            ? _contestRepository
            : StubContestRepository(),
      );

  @override
  core.ContestRepository get contestRepository => _contestRepository;

  final core.ContestRepository _contestRepository;

  /// The participant profiles, participations and roles, and the matrix
  /// assignments, for tests to inspect and arrange.
  final accounts = StubAccountRepository();
  final accountAliases = StubAccountAliasRepository();
  final participantProfiles = StubParticipantProfileRepository();
  final participations = StubContestParticipationRepository();
  final roles = StubRoleRepository();
  final teams = StubTeamRepository();
  final landingTables = StubLandingTableRepository();
  final teamMemberships = StubTeamMembershipRepository();
  final rounds = StubRoundRepository();
  final roundGroups = StubRoundGroupRepository();
  final scorePlaceholders = StubScorePlaceholderRepository();
  late final scoreAttempts = StubScoreAttemptRepository();
  late final officialScores = StubOfficialScoreRepository(
    _contestRepository as StubContestRepository,
    scorePlaceholders,
    scoreAttempts,
  );
  late final matrixAssignments = StubMatrixAssignmentRepository()
    ..placeholders = scorePlaceholders
    ..participations = participations;
  late final matrixRevisions = StubMatrixRevisionRepository(
    _contestRepository as StubContestRepository,
    participations,
    rounds,
    roundGroups,
    matrixAssignments,
    scorePlaceholders,
  );

  final flightResults = StubFlightResultRepository();
  final participationStandings = StubParticipationStandingRepository();
  final teamStandings = StubTeamStandingRepository();
  late final results = StubResultsRepository(
    flightResults,
    participationStandings,
    teamStandings,
  );

  /// The stored configuration revisions, for tests to inspect.
  final StubConfigurationRevisionRepository configurations;

  @override
  core.ContestConfigurationRevisionRepository
  get contestConfigurationRevisionRepository => configurations;

  @override
  core.AccountRepository get accountRepository => accounts;

  @override
  core.AccountAliasRepository get accountAliasRepository => accountAliases;

  @override
  core.ParticipantProfileRepository get participantProfileRepository =>
      participantProfiles;

  @override
  core.ContestParticipationRepository get contestParticipationRepository =>
      participations;

  @override
  core.RoleRepository get roleRepository => roles;

  @override
  core.MatrixAssignmentRepository get matrixAssignmentRepository =>
      matrixAssignments;

  @override
  core.TeamRepository get teamRepository => teams;

  @override
  core.TeamMembershipRepository get teamMembershipRepository => teamMemberships;

  @override
  core.MatrixRevisionRepository get matrixRevisionRepository => matrixRevisions;

  @override
  core.RoundRepository get roundRepository => rounds;

  @override
  core.RoundGroupRepository get roundGroupRepository => roundGroups;

  @override
  core.ScorePlaceholderRepository get scorePlaceholderRepository =>
      scorePlaceholders;

  @override
  core.ScoreAttemptRepository get scoreAttemptRepository => scoreAttempts;

  @override
  core.OfficialScoreRepository get officialScoreRepository => officialScores;

  @override
  core.DisciplineProfileRepository get disciplineProfileRepository =>
      StubDisciplineProfileRepository();

  @override
  core.LandingTableRepository get landingTableRepository => landingTables;

  @override
  core.FlightResultRepository get flightResultRepository => flightResults;

  @override
  core.ParticipationStandingRepository get participationStandingRepository =>
      participationStandings;

  @override
  core.TeamStandingRepository get teamStandingRepository => teamStandings;

  @override
  core.ResultsRepository get resultsRepository => results;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}
