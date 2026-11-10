import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'matrix_pilot.dart';
import 'team_marker.dart';

/// Everything the matrix page shows about one contest.
class MatrixPageData {
  MatrixPageData({
    required this.contest,
    required this.configuration,
    required this.participations,
    required this.profiles,
    required this.teams,
    required this.memberships,
    required this.matrix,
  }) : markers = _teamsEnabled(configuration, teams)
           ? TeamMarkers.of(teams)
           : TeamMarkers.of(const []),
       _profiles = {for (final profile in profiles) profile.id: profile},
       _teamOf = {
         for (final membership in memberships)
           membership.contestParticipationId: membership.teamId,
       };

  /// The page data read from a report-data response that carries the facts.
  factory MatrixPageData.fromReportData(ReportData data) => MatrixPageData(
    contest: data.contest,
    configuration: data.configuration,
    participations: data.participations!,
    profiles: data.participants!,
    teams: data.teams!,
    memberships: data.teamMemberships!,
    matrix: data.matrix!,
  );

  /// Teams show only when the contest has them configured.
  static bool _teamsEnabled(
    ContestConfigurationRevision? configuration,
    List<Team> teams,
  ) {
    try {
      final options = configuration?.config.coreOptions;
      return options?.teamsEnabled ?? teams.isNotEmpty;
    } on ArgumentError {
      return teams.isNotEmpty;
    }
  }

  /// Loads the contest and everything else in parallel.
  static Future<MatrixPageData> load(ApiClient client, Id id) async {
    // Future.wait, not a record's wait, so a failure keeps its own type.
    final results = await Future.wait<Object?>([
      client.contest(id),
      _readRest(client, id),
    ]);
    return (results[1]! as MatrixPageData Function(Contest))(
      results[0]! as Contest,
    );
  }

  /// Loads everything but the contest, for a caller that already holds
  /// [contest] and so does not fetch it again.
  static Future<MatrixPageData> forContest(
    ApiClient client,
    Contest contest,
  ) async => (await _readRest(client, contest.id))(contest);

  /// The one list of reads behind the page, as a builder that takes the
  /// contest.
  static Future<MatrixPageData Function(Contest)> _readRest(
    ApiClient client,
    Id id,
  ) async {
    final results = await Future.wait<Object?>([
      latestConfiguration(client, id),
      client.participations(id),
      client.participants(),
      client.teams(id),
      client.teamMemberships(id),
      client.matrix(id),
    ]);
    return (contest) => MatrixPageData(
      contest: contest,
      configuration: results[0] as ContestConfigurationRevision?,
      participations: results[1]! as List<ContestParticipation>,
      profiles: results[2]! as List<ParticipantProfile>,
      teams: results[3]! as List<Team>,
      memberships: results[4]! as List<TeamMembership>,
      matrix: results[5]! as CurrentMatrix,
    );
  }

  /// The latest saved configuration, or `null` when none is saved yet.
  static Future<ContestConfigurationRevision?> latestConfiguration(
    ApiClient client,
    Id id,
  ) async {
    try {
      return await client.configuration(id);
    } on ApiHttpError catch (error) {
      if (error.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  final Contest contest;
  final ContestConfigurationRevision? configuration;
  final List<ContestParticipation> participations;
  final List<ParticipantProfile> profiles;
  final List<Team> teams;
  final List<TeamMembership> memberships;
  final CurrentMatrix matrix;

  /// Empty when the contest has no teams, so nothing team-related shows.
  final TeamMarkers markers;

  /// Pilot numbers show only when the contest uses them.
  bool get showNumbers => options?.participantNumbersEnabled ?? false;

  bool get showTeams => markers.ordered.isNotEmpty;
  final Map<Id, ParticipantProfile> _profiles;
  final Map<Id, Id> _teamOf;

  /// This data with [drawn] as the matrix, after a draw.
  MatrixPageData withMatrix(CurrentMatrix drawn) => MatrixPageData(
    contest: contest,
    configuration: configuration,
    participations: participations,
    profiles: profiles,
    teams: teams,
    memberships: memberships,
    matrix: drawn,
  );

  /// The contest options, or `null` when none are saved or they are invalid.
  CoreOptions? get options {
    try {
      return configuration?.config.coreOptions;
    } on ArgumentError {
      return null;
    }
  }

  /// Pilots who fly: not non-fliers, not retired.
  int get scoringPilots => participations
      .where(
        (participation) =>
            participation.roleType == RoleType.pilot &&
            participation.retiredAtRound == null,
      )
      .length;

  int get nonFlyingParticipants => participations.length - scoringPilots;

  Map<Id, int> get _teamSizes {
    final sizes = <Id, int>{};
    for (final participation in participations) {
      final team = _teamOf[participation.id];
      if (team != null &&
          participation.roleType == RoleType.pilot &&
          participation.retiredAtRound == null) {
        sizes[team] = (sizes[team] ?? 0) + 1;
      }
    }
    return sizes;
  }

  /// The size of the largest team among the scoring pilots; 0 without teams.
  int get largestTeam => _teamSizes.values.fold(0, (a, b) => a > b ? a : b);

  String? get largestTeamName {
    final sizes = _teamSizes;
    final best = largestTeam;
    for (final (id, marker) in markers.ordered) {
      if (best > 0 && sizes[id] == best) {
        return marker.name;
      }
    }
    return null;
  }

  /// The number of scoring pilots on [teamId].
  int teamSize(Id teamId) => _teamSizes[teamId] ?? 0;

  /// Every participant by participation id.
  Map<Id, MatrixPilot> get pilots => {
    for (final participation in participations)
      participation.id: _pilot(participation),
  };

  MatrixPilot _pilot(ContestParticipation participation) {
    final profile = _profiles[participation.participantProfileId];
    return MatrixPilot(
      participationId: participation.id,
      number: showNumbers ? participation.participantNumber : null,
      name: profile == null
          ? 'Unknown pilot'
          : '${profile.firstName} ${profile.lastName}'.trim(),
      role: participation.roleName,
      teamId: _teamOf[participation.id],
      retiredAtRound: participation.retiredAtRound,
    );
  }
}
