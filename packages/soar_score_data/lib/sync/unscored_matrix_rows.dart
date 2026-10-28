import 'package:soar_score_core/soar_score_core.dart' as core;

import 'entity_store.dart';
import 'entity_stores.dart';

/// Removes the matrix rows of a pilot with no scores inside [context]'s
/// transaction: each assignment and its empty score slot with a tombstone,
/// the results derived from them without one. Returns how many assignments
/// went.
///
/// Throws a [core.ContestStateError] (`has_scores`), before changing anything,
/// when a slot holds a score or the pilot has a re-flight.
Future<int> removeUnscoredMatrixRows(
  core.WriteContext context,
  EntityStores stores,
  core.Id participationId,
  core.MutationMetadata metadata,
) async {
  final assignmentStore = stores.of('MatrixAssignment');
  final placeholderStore = stores.of('ScorePlaceholder');
  final assignments = [
    for (final a in await _where<core.MatrixAssignment>(
      assignmentStore,
      participationId,
    ))
      a,
  ];
  final placeholders = await _where<core.ScorePlaceholder>(
    placeholderStore,
    participationId,
  );
  final reFlights = await stores
      .of('ReFlightParticipant')
      .whereIdJson('contest_participation_id', participationId);
  if (reFlights.isNotEmpty ||
      placeholders.any(
        (p) =>
            p.state != core.ScorePlaceholderState.notEntered ||
            p.scoreRevision > 0,
      )) {
    throw core.ContestStateError(
      'has_scores',
      'a participant with scores cannot be removed from the draw; retire the '
          'pilot instead',
    );
  }
  if (assignments.isEmpty) return 0;

  // Derived rows are recomputed, never mutated, so they leave without a
  // tombstone.
  for (final type in ['FlightResult', 'ParticipationStanding']) {
    await stores
        .of(type)
        .removeWhereId('contest_participation_id', participationId);
  }
  final placeholderOf = {for (final p in placeholders) p.assignmentId: p};
  // A move points at its source, so the moved row goes before it.
  for (final assignment in _movesFirst(assignments)) {
    final placeholder = placeholderOf[assignment.id];
    if (placeholder != null) {
      await context.delete(
        placeholder,
        metadata: metadata.forPart(placeholder.id.value),
      );
    }
    await context.removeAssignment(
      assignment,
      metadata: metadata.forPart(assignment.id.value),
    );
  }
  return assignments.length;
}

Future<List<T>> _where<T extends Object>(
  EntityStore<Object> store,
  core.Id participationId,
) async => [
  for (final row in await store.whereId(
    'contest_participation_id',
    participationId,
    orderBy: store.entityType == 'MatrixAssignment' ? 'created_at, id' : null,
  ))
    row as T,
];

/// [assignments] with every row ahead of the row it moves from.
List<core.MatrixAssignment> _movesFirst(
  List<core.MatrixAssignment> assignments,
) {
  final byId = {for (final a in assignments) a.id: a};
  int depth(core.MatrixAssignment a) {
    var n = 0;
    for (
      var source = byId[a.sourceAssignmentId];
      source != null;
      source = byId[source.sourceAssignmentId]
    ) {
      n++;
    }
    return n;
  }

  return [...assignments]..sort((a, b) => depth(b).compareTo(depth(a)));
}
