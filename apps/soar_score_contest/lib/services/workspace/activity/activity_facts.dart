import 'package:equatable/equatable.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'activity_entry.dart';

/// The newest audit events of a contest, turned into [ActivityEntry] lines.
///
/// The events the workspace lists are state transitions, configuration saves
/// and matrix draws, plus successful publications; other events are skipped.
class ActivityFacts extends Equatable {
  const ActivityFacts({this.entries = const [], this.failed = false});

  /// Nothing to show and nothing wrong.
  static const none = ActivityFacts();

  /// The audit read failed; the card offers a retry.
  static const unavailable = ActivityFacts(failed: true);

  /// How many lines the card shows.
  static const shown = 5;

  /// Reads [events], which may come from more than one read; they are put
  /// newest first here.
  factory ActivityFacts.of(
    List<AuditEventDto> events, {
    String? actingAccountId,
  }) {
    final newestFirst = [...events]
      ..sort((a, b) {
        final byTime = b.serverTimestamp.compareTo(a.serverTimestamp);
        // Events stored in the same instant (a save and the draw after it)
        // keep a fixed order: ids are created in increasing order.
        return byTime != 0 ? byTime : b.id.value.compareTo(a.id.value);
      });
    final entries = <ActivityEntry>[];
    for (final event in newestFirst) {
      final kind = _kindOf(event);
      if (kind == null) {
        continue;
      }
      final actor = event.actorId?.value;
      entries.add(
        ActivityEntry(
          id: event.id.value,
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
      AuditAction.configurationSaved => ActivityKind.configurationSaved,
      AuditAction.matrixDrawn => ActivityKind.matrixDrawn,
      AuditAction.stateTransition => switch (event.transition) {
        ContestAction.complete => ActivityKind.complete,
        ContestAction.openScoring => ActivityKind.openScoring,
        ContestAction.closeScoring => ActivityKind.closeScoring,
        ContestAction.lock => ActivityKind.lock,
        ContestAction.unlock => ActivityKind.unlock,
        // No activity line for results hiding yet; #658 adds the card.
        ContestAction.hideResults || ContestAction.showResults => null,
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
