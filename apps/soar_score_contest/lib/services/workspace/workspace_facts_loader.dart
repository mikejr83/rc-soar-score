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
  /// is thrown; a failure of the scores, publication or landing-table read is
  /// recorded in [WorkspaceFacts.unavailable] and the rest still loads.
  static Future<WorkspaceFacts> load(
    ApiClient client,
    Contest contest, {
    bool isOffline = false,
  }) async {
    final id = contest.id;
    final unavailable = <WorkspaceFactSource>{};
    final results = await Future.wait<Object?>([
      MatrixPageData.forContest(client, contest),
      _scores(client, id, unavailable),
      _publication(client, id, unavailable),
      _landingTables(client, unavailable),
    ]);
    return WorkspaceFacts.derive(
      data: results[0]! as MatrixPageData,
      scores: results[1] as ContestScores?,
      publication: results[2]! as PublicationFacts,
      landingTables: results[3] as List<LandingTableView>?,
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

  static Future<List<LandingTableView>?> _landingTables(
    ApiClient client,
    Set<WorkspaceFactSource> unavailable,
  ) async {
    try {
      return await client.landingTables();
    } on Object {
      unavailable.add(WorkspaceFactSource.landingTables);
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
