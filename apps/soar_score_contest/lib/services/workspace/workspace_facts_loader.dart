import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/matrix_page_data.dart';
import 'publication_facts.dart';
import 'workspace_fact_source.dart';
import 'workspace_facts.dart';

/// Loads what [WorkspaceFacts] reduces. The contest is already loaded (the
/// shell owns it), so it is not fetched again.
abstract final class WorkspaceFactsLoader {
  /// A failure of the core reads (configuration, participants, teams, matrix)
  /// is thrown; a failure of the scores or publication read is recorded in
  /// [WorkspaceFacts.unavailable] and the rest still loads.
  static Future<WorkspaceFacts> load(
    ApiClient client,
    Contest contest, {
    bool isOffline = false,
  }) async {
    final id = contest.id;
    final unavailable = <WorkspaceFactSource>{};
    final results = await Future.wait<Object?>([
      MatrixPageData.latestConfiguration(client, id),
      client.participations(id),
      client.participants(),
      client.teams(id),
      client.teamMemberships(id),
      client.matrix(id),
      _scores(client, id, unavailable),
      _publication(client, id, unavailable),
    ]);
    final data = MatrixPageData(
      contest: contest,
      configuration: results[0] as ContestConfigurationRevision?,
      participations: results[1]! as List<ContestParticipation>,
      profiles: results[2]! as List<ParticipantProfile>,
      teams: results[3]! as List<Team>,
      memberships: results[4]! as List<TeamMembership>,
      matrix: results[5]! as CurrentMatrix,
    );
    return WorkspaceFacts.derive(
      data: data,
      scores: results[6] as ContestScores?,
      publication: results[7]! as PublicationFacts,
      unavailable: unavailable,
      isOffline: isOffline,
    );
  }

  static Future<ContestScores?> _scores(
    ApiClient client,
    Id id,
    Set<WorkspaceFactSource> unavailable,
  ) async {
    try {
      return await client.scores(id);
    } on Object {
      unavailable.add(WorkspaceFactSource.scores);
      return null;
    }
  }

  static Future<PublicationFacts> _publication(
    ApiClient client,
    Id id,
    Set<WorkspaceFactSource> unavailable,
  ) async {
    try {
      return PublicationFacts.fromJson(await client.publication(id));
    } on ApiHttpError catch (error) {
      if (error.statusCode == 404) {
        return PublicationFacts.notPublished;
      }
    } on Object {
      // Falls through to unavailable.
    }
    unavailable.add(WorkspaceFactSource.publication);
    return PublicationFacts.unknown;
  }
}
