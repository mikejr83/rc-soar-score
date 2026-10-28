/// How the last attempt to store a row ended.
enum RowOutcome {
  /// Nothing happened since the row was loaded.
  none,

  /// The row is being saved.
  saving,

  /// The last save worked.
  saved,

  /// The last save failed; the typed values are kept.
  failed,

  /// Someone else changed the participant since the page read it.
  stale,

  /// The person was just added to the contest.
  added,
}

/// A row's [RowOutcome] with the server's words for a failure.
class RowState {
  const RowState(this.outcome, {this.message, this.late = false});

  final RowOutcome outcome;
  final String? message;

  /// For [RowOutcome.added]: the person joined after the draw.
  final bool late;
}

/// The result of removing the selected people.
class RemoveResult {
  const RemoveResult({required this.removed, required this.refused});

  /// Names of the people removed from the contest.
  final List<String> removed;

  /// Names of the people that stayed, with the reason.
  final List<({String name, String reason})> refused;

  bool get isPartial => removed.isNotEmpty && refused.isNotEmpty;
}
