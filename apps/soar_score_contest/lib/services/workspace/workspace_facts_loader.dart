import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/matrix_page_data.dart';
import 'activity/activity_facts.dart';
import 'publication_facts.dart';
import 'transition_facts.dart';
import 'workspace_fact_source.dart';
import 'workspace_facts.dart';

final Logger _logger = Logger('WorkspaceFactsLoader');

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
      _audit(client, contest, actingAccountId),
    ]);
    final audit = results[4]! as (TransitionFacts, ActivityFacts);
    return WorkspaceFacts.derive(
      data: results[0]! as MatrixPageData,
      scores: results[1] as ContestScores?,
      publication: results[2]! as PublicationFacts,
      landingTables: results[3] as List<LandingTableView>?,
      transitions: audit.$1,
      activity: audit.$2,
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

  /// Reads the audit trail once for the completion and lock facts and the
  /// activity card: every state transition, plus the newest publication
  /// events. Asking by action keeps other events (score edits, say) from
  /// pushing the ones listed out of a limited read.
  ///
  /// A failed read leaves the transition facts unknown and marks the
  /// activity as failed; the rest of the page still loads.
  static Future<(TransitionFacts, ActivityFacts)> _audit(
    ApiClient client,
    Contest contest,
    String? actingAccountId,
  ) async {
    try {
      final (transitions, publications) = await (
        client.auditEvents(contest.id, action: AuditAction.stateTransition),
        client.auditEvents(
          contest.id,
          action: AuditAction.publicationAttempt,
          limit: ActivityFacts.shown,
        ),
      ).wait;
      return (
        TransitionFacts.of(
          contest,
          transitions,
          actingAccountId: actingAccountId,
        ),
        ActivityFacts.of([
          ...transitions,
          ...publications,
        ], actingAccountId: actingAccountId),
      );
    } on Object catch (error) {
      _logger.warning('Could not read the audit trail of ${contest.id}', error);
      return (TransitionFacts.unknown, ActivityFacts.unavailable);
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
      if (error.statusCode == 409 &&
          error.error?.code == 'publishing_not_available') {
        // This server does not publish contests; a stable state, not a
        // failed read, so it leaves [unavailable] untouched.
        return PublicationFacts.unsupported;
      }
    } on Object {
      // Falls through to unavailable.
    }
    unavailable.add(WorkspaceFactSource.publication);
    return PublicationFacts.unknown;
  }
}
