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
class ActivityLogPage {
  const ActivityLogPage({
    required this.entries,
    required this.hasMore,
    required this.incomplete,
  });

  /// The lines of this page, newest first.
  final List<ActivityEntry> entries;

  /// Whether older lines may follow.
  final bool hasMore;

  /// Whether a source that may fail without failing the list could not be
  /// read, so lines are missing from it (publications, when the publishing
  /// server does not answer). Reading again from the start fills them in.
  final bool incomplete;
}

/// One place the audit events are read from, with its own paging position.
class _Source {
  _Source(
    this.client,
    this.contestId,
    this.action, {
    this.skipPublication = false,
    this.tolerant = false,
    this.optional = false,
    this.actingAccountId,
  });

  final ApiClient client;
  final Id contestId;
  final AuditAction? action;

  /// Drops publication events: another source reads them from where they
  /// are recorded.
  final bool skipPublication;

  /// Reads that fail with 401 or 404 count as no events: a director who is
  /// signed out of the publishing server, or whose contest is not on it yet,
  /// has none there, which is not a failed read.
  final bool tolerant;

  /// A failing read drops this source from the list ([failed]) instead of
  /// failing it: the other sources stay readable.
  final bool optional;
  final String? actingAccountId;

  /// An [optional] source whose read failed; it gives no more lines.
  bool failed = false;

  /// Lines read and not yet handed out, newest first.
  final List<ActivityEntry> buffer = [];
  int _offset = 0;
  bool exhausted = false;

  /// Reads until [buffer] holds a line or the events run out.
  Future<void> fill() async {
    while (buffer.isEmpty && !exhausted) {
      final List<AuditEventDto> events;
      try {
        events = await client.auditEvents(
          contestId,
          action: action,
          limit: ActivityLogReader.readSize,
          offset: _offset,
        );
      } on ApiHttpError catch (error) {
        if (tolerant && (error.statusCode == 401 || error.statusCode == 404)) {
          exhausted = true;
          return;
        }
        if (optional) {
          failed = true;
          exhausted = true;
          return;
        }
        rethrow;
      } on Object {
        if (optional) {
          failed = true;
          exhausted = true;
          return;
        }
        rethrow;
      }
      _offset += events.length;
      exhausted = events.length < ActivityLogReader.readSize;
      for (final event in events) {
        if (skipPublication && event.action == AuditAction.publicationAttempt) {
          continue;
        }
        final entry = ActivityFacts.entryOf(
          event,
          actingAccountId: actingAccountId,
        );
        if (entry != null) {
          buffer.add(entry);
        }
      }
    }
  }

  bool get hasMore => buffer.isNotEmpty || !exhausted;
}

/// Reads a contest's audit events page by page and turns them into
/// [ActivityEntry] lines, newest first.
///
/// On a build whose publishing server differs from the app's own (native:
/// the embedded server and the hosted one), publication events are recorded
/// only on the hosted server, so they are read from there and merged with
/// the rest. Each source keeps its own position, so loading more neither
/// skips nor repeats an event, whatever the interleaving. A reader is one
/// filter's walk through the list; make a new one to start again.
class ActivityLogReader {
  ActivityLogReader(
    ApiClient client,
    Id contestId, {
    ActivityFilter filter = ActivityFilter.all,
    ApiClient? publicationClient,
    String? actingAccountId,
  }) : _sources = _sourcesFor(
         client,
         contestId,
         filter,
         publicationClient,
         actingAccountId,
       );

  /// How many lines a page aims for.
  static const pageSize = 25;

  /// How many events one API read asks for. Larger than [pageSize] because
  /// events the list does not show (routine first score entries) are
  /// skipped.
  static const readSize = 50;

  final List<_Source> _sources;

  static List<_Source> _sourcesFor(
    ApiClient client,
    Id contestId,
    ActivityFilter filter,
    ApiClient? publicationClient,
    String? actingAccountId,
  ) {
    _Source local({bool skipPublication = false}) => _Source(
      client,
      contestId,
      filter.action,
      skipPublication: skipPublication,
      actingAccountId: actingAccountId,
    );
    final hosted = publicationClient;
    if (hosted == null || identical(hosted, client)) {
      return [local()];
    }
    // Beside local events the publications may fail without taking the local
    // history with them; alone they are the whole list.
    _Source publication({required bool optional}) => _Source(
      hosted,
      contestId,
      AuditAction.publicationAttempt,
      tolerant: true,
      optional: optional,
      actingAccountId: actingAccountId,
    );
    return switch (filter) {
      ActivityFilter.publication => [publication(optional: false)],
      ActivityFilter.all => [
        local(skipPublication: true),
        publication(optional: true),
      ],
      _ => [local()],
    };
  }

  /// Whether older lines may follow what was read so far.
  bool get hasMore => _sources.any((source) => source.hasMore);

  /// Whether an optional source failed, so its lines are missing.
  bool get incomplete => _sources.any((source) => source.failed);

  /// The next [pageSize] lines (fewer at the end of the list).
  Future<ActivityLogPage> next() async {
    final entries = <ActivityEntry>[];
    final taken = <(_Source, ActivityEntry)>[];
    try {
      await _take(entries, taken);
    } on Object {
      // A failed read must not lose the lines already taken: a retry
      // continues from where this page began.
      for (final (source, entry) in taken.reversed) {
        source.buffer.insert(0, entry);
      }
      rethrow;
    }
    return ActivityLogPage(
      entries: List.unmodifiable(entries),
      hasMore: hasMore,
      incomplete: incomplete,
    );
  }

  Future<void> _take(
    List<ActivityEntry> entries,
    List<(_Source, ActivityEntry)> taken,
  ) async {
    while (entries.length < pageSize) {
      for (final source in _sources) {
        await source.fill();
      }
      _Source? newest;
      for (final source in _sources) {
        if (source.buffer.isEmpty) {
          continue;
        }
        if (newest == null ||
            _newer(source.buffer.first, newest.buffer.first)) {
          newest = source;
        }
      }
      if (newest == null) {
        break;
      }
      final entry = newest.buffer.removeAt(0);
      entries.add(entry);
      taken.add((newest, entry));
    }
  }

  /// Newer first; events stored in the same instant keep a fixed order, as
  /// ids are created in increasing order.
  static bool _newer(ActivityEntry a, ActivityEntry b) {
    final byTime = a.at.compareTo(b.at);
    return byTime != 0 ? byTime > 0 : a.id.compareTo(b.id) > 0;
  }
}
