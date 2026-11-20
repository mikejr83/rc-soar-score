/// What standings produced now would be called. Never colour alone: every
/// status has a word and an icon where it is shown.
///
/// In director reports, completed standings can be official with blank flights.
enum ResultStatus {
  /// Every score counted is official.
  official('Official'),

  /// Standings are stale, a score is unresolved, or scoring is still open
  /// with missing scores.
  preliminary('Preliminary'),

  /// Nothing is scored yet, so there are no standings.
  none('No standings yet');

  const ResultStatus(this.label);

  final String label;
}
