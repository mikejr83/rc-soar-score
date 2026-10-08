import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'config_phase.dart';
import 'matrix_summary.dart';

/// Everything the configuration page shows about one contest.
class ConfigurationData {
  const ConfigurationData({
    required this.contest,
    required this.configuration,
    required this.participations,
    required this.matrix,
    required this.landingTables,
    required this.teamCount,
  });

  /// Loads the contest, its latest configuration revision (`null` when none
  /// is saved yet), its participants, teams, matrix and the landing tables
  /// that can be chosen.
  static Future<ConfigurationData> load(ApiClient client, Id id) async {
    final results = await Future.wait<Object?>([
      client.contest(id),
      _latestConfiguration(client, id),
      client.participations(id),
      client.matrix(id),
      client.landingTables(),
      client.teams(id),
    ]);
    return ConfigurationData(
      contest: results[0]! as Contest,
      configuration: results[1] as ContestConfigurationRevision?,
      participations: results[2]! as List<ContestParticipation>,
      matrix: MatrixSummary.of(results[3]! as CurrentMatrix),
      landingTables: results[4]! as List<LandingTableView>,
      teamCount: (results[5]! as List<Team>).length,
    );
  }

  static Future<ContestConfigurationRevision?> _latestConfiguration(
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

  /// `null` until a matrix is drawn.
  final MatrixSummary? matrix;

  /// The system tables and the director's own.
  final List<LandingTableView> landingTables;
  final int teamCount;

  ConfigPhase get phase => ConfigPhase.of(contest, matrixDrawn: matrix != null);

  /// Whether nobody may edit the configuration: the contest is locked or
  /// completed.
  bool get readOnly =>
      contest.adminLock == AdminLock.locked ||
      contest.lifecycleState == LifecycleState.completed;

  /// The system profile of the saved configuration; `null` when none is
  /// saved or the profile is not a system one.
  DisciplineProfileWithRules? get profile {
    final id = configuration?.disciplineProfileId;
    for (final profile in SystemDisciplineProfiles.all) {
      if (profile.profile.id == id) {
        return profile;
      }
    }
    return null;
  }

  LandingTableView? landingTable(Id? id) {
    for (final view in landingTables) {
      if (view.table.id == id) {
        return view;
      }
    }
    return null;
  }

  /// Pilots who fly: not non-fliers, not retired.
  int get scoringPilots => participations
      .where(
        (participation) =>
            participation.roleType == RoleType.pilot &&
            participation.retiredAtRound == null,
      )
      .length;

  ConfigurationData withContest(Contest next) => ConfigurationData(
    contest: next,
    configuration: configuration,
    participations: participations,
    matrix: matrix,
    landingTables: landingTables,
    teamCount: teamCount,
  );

  ConfigurationData withSaved(SavedConfiguration saved) => ConfigurationData(
    contest: saved.contest,
    configuration: saved.revision,
    participations: participations,
    matrix: matrix,
    landingTables: landingTables,
    teamCount: teamCount,
  );
}
