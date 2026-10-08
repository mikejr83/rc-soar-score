import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'matrix_summary.dart';

/// Everything the configuration page shows about one contest.
class ConfigurationData {
  const ConfigurationData({
    required this.contest,
    required this.configuration,
    required this.participations,
    required this.matrix,
  });

  /// Loads the contest, its latest configuration revision (`null` when none
  /// is saved yet), its participants and its matrix.
  static Future<ConfigurationData> load(ApiClient client, Id id) async {
    final results = await Future.wait<Object?>([
      client.contest(id),
      _latestConfiguration(client, id),
      client.participations(id),
      client.matrix(id),
    ]);
    return ConfigurationData(
      contest: results[0]! as Contest,
      configuration: results[1] as ContestConfigurationRevision?,
      participations: results[2]! as List<ContestParticipation>,
      matrix: MatrixSummary.of(results[3]! as CurrentMatrix),
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

  /// Pilots who fly: not non-fliers, not retired.
  int get scoringPilots => participations
      .where(
        (participation) =>
            participation.roleType == RoleType.pilot &&
            participation.retiredAtRound == null,
      )
      .length;

  ConfigurationData withSaved(SavedConfiguration saved) => ConfigurationData(
    contest: saved.contest,
    configuration: saved.revision,
    participations: participations,
    matrix: matrix,
  );
}
