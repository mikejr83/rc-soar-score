import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/matrix_page_data.dart';
import 'activity/activity_facts.dart';
import 'publication_facts.dart';
import 'publication_facts_loader.dart';
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
  ///
  /// The publication is read through [publicationClient], the hosted server
  /// on native; it defaults to [client].
  static Future<WorkspaceFacts> load(
    ApiClient client,
    Contest contest, {
    ApiClient? publicationClient,
    bool isOffline = false,
    String? actingAccountId,
  }) async {
    final id = contest.id;
    final unavailable = <WorkspaceFactSource>{};
    final results = await Future.wait<Object?>([
      MatrixPageData.forContest(client, contest),
      _scores(client, id, unavailable),
      _publication(publicationClient ?? client, id, unavailable),
      _landingTables(client, unavailable),
      _audit(client, publicationClient ?? client, contest, actingAccountId),
    ]);
    final audit = results[4]! as _AuditFacts;
    return WorkspaceFacts.derive(
      data: results[0]! as MatrixPageData,
      scores: results[1] as ContestScores?,
      publication: results[2]! as PublicationFacts,
      landingTables: results[3] as List<LandingTableView>?,
      transitions: audit.transitions,
      activity: audit.activity,
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

  /// Reads the audit trail for the completion and lock facts and the activity
  /// card: every state transition, every configuration save and matrix draw,
  /// plus the newest score corrections and publication events. Asking by action keeps other events
  /// (score edits, say) from pushing the ones listed out of a limited read,
  /// and the server applies no limit unless one is passed, so no transition
  /// is cut off.
  ///
  /// The reads fail on their own: a failed publication read still leaves the
  /// transition facts known, and marks only the activity as failed.
  ///
  /// Publishing happens on the hosted server, so the publication events are
  /// read from [publicationClient]; the rest come from [client].
  static Future<_AuditFacts> _audit(
    ApiClient client,
    ApiClient publicationClient,
    Contest contest,
    String? actingAccountId,
  ) async {
    final (
      transitions,
      configurations,
      draws,
      corrections,
      publications,
    ) = await (
      _auditEvents(client, contest, AuditAction.stateTransition),
      _auditEvents(
        client,
        contest,
        AuditAction.configurationSaved,
        limit: ActivityFacts.shown,
      ),
      _auditEvents(
        client,
        contest,
        AuditAction.matrixDrawn,
        limit: ActivityFacts.shown,
      ),
      _auditEvents(
        client,
        contest,
        AuditAction.scoreAttempt,
        limit: ActivityFacts.shown,
      ),
      _publicationEvents(publicationClient, contest),
    ).wait;
    final activityReads = [
      transitions,
      configurations,
      draws,
      corrections,
      publications,
    ];
    return _AuditFacts(
      transitions: transitions == null
          ? TransitionFacts.unknown
          : TransitionFacts.of(
              contest,
              transitions,
              actingAccountId: actingAccountId,
            ),
      activity: activityReads.any((read) => read == null)
          ? ActivityFacts.unavailable
          : ActivityFacts.of([
              ...transitions!,
              ...configurations!,
              ...draws!,
              ...corrections!,
              ...publications!,
            ], actingAccountId: actingAccountId),
    );
  }

  /// The publication events of [contest] on the server that publishes. A
  /// director who is signed out (401) or whose contest has not synced yet
  /// (404) has none there, which is not a failed read.
  static Future<List<AuditEventDto>?> _publicationEvents(
    ApiClient client,
    Contest contest,
  ) async {
    try {
      return await client.auditEvents(
        contest.id,
        action: AuditAction.publicationAttempt,
        limit: ActivityFacts.shown,
      );
    } on ApiHttpError catch (error) {
      if (error.statusCode == 401 || error.statusCode == 404) {
        return const <AuditEventDto>[];
      }
      _logger.warning(
        'Could not read the publication audit events of ${contest.id}',
        error,
      );
      return null;
    } on Object catch (error) {
      _logger.warning(
        'Could not read the publication audit events of ${contest.id}',
        error,
      );
      return null;
    }
  }

  static Future<List<AuditEventDto>?> _auditEvents(
    ApiClient client,
    Contest contest,
    AuditAction action, {
    int? limit,
  }) async {
    try {
      return await client.auditEvents(contest.id, action: action, limit: limit);
    } on Object catch (error) {
      _logger.warning(
        'Could not read the ${action.name} audit events of ${contest.id}',
        error,
      );
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
    final facts = await PublicationFactsLoader.load(client, id);
    if (!facts.isKnown) {
      unavailable.add(WorkspaceFactSource.publication);
    }
    return facts;
  }
}

/// What one audit read yields for the workspace.
class _AuditFacts {
  const _AuditFacts({required this.transitions, required this.activity});

  final TransitionFacts transitions;
  final ActivityFacts activity;
}
