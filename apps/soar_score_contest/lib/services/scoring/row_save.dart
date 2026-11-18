/// Where a row's save stands.
enum RowSaveKind {
  /// Nothing in flight.
  idle,

  /// The request is out; the row is locked so it cannot be sent twice.
  saving,

  /// The request did not complete. The values are kept; retry or refresh.
  failed,

  /// The row changed since it was loaded (another operator or a participant
  /// submission). The director chooses.
  stale,

  /// The server refused the entry (lock, state, rules). Reload or fix.
  refused,
}

class RowSave {
  const RowSave(
    this.kind, {
    this.message,
    this.networkProblem = false,
    this.promotion = false,
    this.changed = false,
    this.confirm = false,
  });

  static const idle = RowSave(RowSaveKind.idle);
  static const saving = RowSave(RowSaveKind.saving);

  final RowSaveKind kind;
  final String? message;

  /// For [RowSaveKind.failed]: true when the server could not be reached, so
  /// Retry is the answer; false when a refresh is.
  final bool networkProblem;

  /// True when the request was "mark official" (accepting the pilot's own
  /// entry) rather than a save of typed values, so the row's banner words it
  /// that way and Retry asks again for the same thing.
  final bool promotion;

  /// For a [promotion] that was refused: the pilot's entry or the score
  /// changed since the director opened the row, and the row now shows the
  /// newer values to check before asking again.
  final bool changed;

  /// True when the [promotion] was the director confirming a score the
  /// contest accepted automatically, so the banner says "confirm".
  final bool confirm;

  bool get isBusy => kind == RowSaveKind.saving;
}
