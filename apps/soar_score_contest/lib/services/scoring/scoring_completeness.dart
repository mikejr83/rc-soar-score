/// How far a group or round has been scored, for the pickers and the context
/// strip. Each state has its own word and icon, so colour is never alone.
enum CompletenessState {
  empty('No scores'),
  partial('Some scores'),
  entered('All entered'),
  official('All official'),
  locked('Locked');

  const CompletenessState(this.label);
  final String label;
}

class Completeness {
  const Completeness._(this.state, this.total, this.entered, this.official);

  factory Completeness.of({
    required int total,
    required int entered,
    required int official,
    required bool locked,
  }) {
    final CompletenessState state;
    if (locked) {
      state = CompletenessState.locked;
    } else if (total > 0 && official == total) {
      state = CompletenessState.official;
    } else if (total > 0 && entered == total) {
      state = CompletenessState.entered;
    } else if (entered > 0) {
      state = CompletenessState.partial;
    } else {
      state = CompletenessState.empty;
    }
    return Completeness._(state, total, entered, official);
  }

  final CompletenessState state;
  final int total;

  /// Flights with a score entered, official or pending.
  final int entered;

  /// Flights with an official score.
  final int official;
}
