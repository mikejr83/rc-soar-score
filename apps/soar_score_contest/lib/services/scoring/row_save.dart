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
  const RowSave(this.kind, {this.message, this.networkProblem = false});

  static const idle = RowSave(RowSaveKind.idle);
  static const saving = RowSave(RowSaveKind.saving);

  final RowSaveKind kind;
  final String? message;

  /// For [RowSaveKind.failed]: true when the server could not be reached, so
  /// Retry is the answer; false when a refresh is.
  final bool networkProblem;

  bool get isBusy => kind == RowSaveKind.saving;
}
