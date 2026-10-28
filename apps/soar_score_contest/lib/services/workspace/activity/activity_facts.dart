import 'package:equatable/equatable.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'activity_entry.dart';

/// The newest audit events of a contest, turned into [ActivityEntry] lines.
///
/// Only state transitions and successful publication events are written
/// today, so only those are listed; other events are skipped.
class ActivityFacts extends Equatable {
  const ActivityFacts({this.entries = const [], this.failed = false});

  /// Nothing to show and nothing wrong.
  static const none = ActivityFacts();

  /// The audit read failed; the card offers a retry.
  static const unavailable = ActivityFacts(failed: true);

  /// How many lines the card shows.
  static const shown = 5;

  /// How many events to ask for, so skipped ones do not leave the list short.
  static const readLimit = 20;

  /// Reads [events] (newest first, as the API returns them).
  factory ActivityFacts.of(
    List<AuditEventDto> events, {
    String? actingAccountId,
  }) {
    final entries = <ActivityEntry>[];
    for (final event in events) {
      final kind = _kindOf(event);
      if (kind == null) {
        continue;
      }
      final actor = event.actorId?.value;
      entries.add(
        ActivityEntry(
          kind: kind,
          byYou: actor != null && actor == actingAccountId,
          at: event.serverTimestamp,
        ),
      );
      if (entries.length == shown) {
        break;
      }
    }
    return ActivityFacts(entries: List.unmodifiable(entries));
  }

  static ActivityKind? _kindOf(AuditEventDto event) {
    if (event.outcome != AuditOutcome.success) {
      return null;
    }
    return switch (event.action) {
      AuditAction.publicationAttempt => ActivityKind.publication,
      AuditAction.stateTransition => switch (event.transition) {
        ContestAction.complete => ActivityKind.complete,
        ContestAction.openScoring => ActivityKind.openScoring,
        ContestAction.closeScoring => ActivityKind.closeScoring,
        ContestAction.lock => ActivityKind.lock,
        ContestAction.unlock => ActivityKind.unlock,
        null => null,
      },
      _ => null,
    };
  }

  /// Newest first.
  final List<ActivityEntry> entries;
  final bool failed;

  @override
  List<Object?> get props => [entries, failed];
}
