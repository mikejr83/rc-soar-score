/// What standings produced now would be called. Never colour alone: every
/// status has a word and an icon where it is shown.
///
/// The rules come from `plan/architecture-requirements/discipline-scoring.md`:
/// a result with missing scores or open reviews is marked preliminary and is
/// not presented as official.
enum ResultStatus {
  /// Every score counted is official.
  official('Official'),

  /// A score counted is missing, submitted but not official, or in review.
  preliminary('Preliminary'),

  /// Nothing is scored yet, so there are no standings.
  none('No standings yet');

  const ResultStatus(this.label);

  final String label;
}
