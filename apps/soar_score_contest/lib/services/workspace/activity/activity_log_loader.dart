import 'package:equatable/equatable.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'activity_entry.dart';
import 'activity_facts.dart';

/// The kinds of event the activity page can narrow its list to. Each is one
/// audit action, which the API filters on; [all] is no filter.
enum ActivityFilter {
  all(null),

  /// Contest actions (scoring opened or closed, lock, complete) and pilot
  /// retirements, which are both state transitions.
  contest(AuditAction.stateTransition),
  scores(AuditAction.scoreAttempt),
  configuration(AuditAction.configurationSaved),
  matrix(AuditAction.matrixDrawn),
  publication(AuditAction.publicationAttempt);

  const ActivityFilter(this.action);

  /// The audit action to ask the API for, or null for every action.
  final AuditAction? action;
}

/// One page of the activity list.
class ActivityLogPage extends Equatable {
  const ActivityLogPage({
    required this.entries,
    required this.nextOffset,
    required this.hasMore,
  });

  /// The lines of this page, newest first.
  final List<ActivityEntry> entries;

  /// Where the next read starts, counted in audit events (not lines: events
  /// the list does not show are skipped but still counted).
  final int nextOffset;

  /// Whether the server may hold older events.
  final bool hasMore;

  @override
  List<Object?> get props => [entries, nextOffset, hasMore];
}

/// Reads the contest's audit events page by page and turns them into
/// [ActivityEntry] lines.
class ActivityLogLoader {
  const ActivityLogLoader(this.client);

  final ApiClient client;

  /// How many lines a page aims for.
  static const pageSize = 25;

  /// How many events one API read asks for. Larger than [pageSize] because
  /// events the list does not show (routine first score entries) are
  /// skipped.
  static const readSize = 50;

  /// Reads from event [offset] on until [pageSize] lines are found or the
  /// events run out. A page can run over [pageSize] by up to a read's worth.
  Future<ActivityLogPage> load(
    Id contestId, {
    ActivityFilter filter = ActivityFilter.all,
    int offset = 0,
    String? actingAccountId,
  }) async {
    final entries = <ActivityEntry>[];
    var next = offset;
    var hasMore = true;
    while (hasMore && entries.length < pageSize) {
      final events = await client.auditEvents(
        contestId,
        action: filter.action,
        limit: readSize,
        offset: next,
      );
      for (final event in events) {
        final entry = ActivityFacts.entryOf(
          event,
          actingAccountId: actingAccountId,
        );
        if (entry != null) {
          entries.add(entry);
        }
      }
      next += events.length;
      hasMore = events.length == readSize;
    }
    return ActivityLogPage(
      entries: List.unmodifiable(entries),
      nextOffset: next,
      hasMore: hasMore,
    );
  }
}
