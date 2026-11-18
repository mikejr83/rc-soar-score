/// A CSV export cannot be built: the data it needs is missing, or the
/// requested range is invalid. The UI shows [message] to the director.
class ScoreExportError implements Exception {
  const ScoreExportError(this.message);

  /// The reason, for the director.
  final String message;

  @override
  String toString() => message;
}
