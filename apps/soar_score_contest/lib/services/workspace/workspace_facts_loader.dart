import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/matrix_page_data.dart';
import 'publication_facts.dart';
import 'transition_facts.dart';
import 'workspace_fact_source.dart';
import 'workspace_facts.dart';

/// Loads what [WorkspaceFacts] reduces. The contest is already loaded (the
/// shell owns it), so it is not fetched again.
abstract final class WorkspaceFactsLoader {
  /// A failure of the core reads (configuration, participants, teams, matrix)
  /// is thrown; a failure of the scores, publication or landing-table read is
  /// recorded in [WorkspaceFacts.unavailable] and the rest still loads. A
  /// failure of the audit read only leaves the completion and lock facts
  /// null, because the cards word themselves without them.
  ///
  /// [actingAccountId] is the account the app acts as, so a lock by it reads
  /// "by you".
  static Future<WorkspaceFacts> load(
    ApiClient client,
    Contest contest, {
    bool isOffline = false,
    String? actingAccountId,
  }) async {
    final id = contest.id;
    final unavailable = <WorkspaceFactSource>{};
    final results = await Future.wait<Object?>([
      MatrixPageData.forContest(client, contest),
      _scores(client, id, unavailable),
      _publication(client, id, unavailable),
      _landingTables(client, unavailable),
      _transitions(client, contest, actingAccountId),
    ]);
    return WorkspaceFacts.derive(
      data: results[0]! as MatrixPageData,
      scores: results[1] as ContestScores?,
      publication: results[2]! as PublicationFacts,
      landingTables: results[3] as List<LandingTableView>?,
      transitions: results[4]! as TransitionFacts,
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

  static Future<TransitionFacts> _transitions(
    ApiClient client,
    Contest contest,
    String? actingAccountId,
  ) async {
    final completed = contest.lifecycleState == LifecycleState.completed;
    final locked = contest.adminLock == AdminLock.locked;
    if (!completed && !locked) {
      return TransitionFacts.unknown;
    }
    try {
      return TransitionFacts.of(
        contest,
        await client.auditEvents(
          contest.id,
          action: AuditAction.stateTransition,
        ),
        actingAccountId: actingAccountId,
      );
    } on Object {
      return TransitionFacts.unknown;
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
