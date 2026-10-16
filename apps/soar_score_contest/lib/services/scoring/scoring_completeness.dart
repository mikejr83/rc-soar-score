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
  const Completeness._(this.state, this.total, this.scored, this.official);

  factory Completeness.of({
    required int total,
    required int scored,
    required int official,
    required bool locked,
  }) {
    final CompletenessState state;
    if (locked) {
      state = CompletenessState.locked;
    } else if (total > 0 && official == total) {
      state = CompletenessState.official;
    } else if (total > 0 && scored == total) {
      state = CompletenessState.entered;
    } else if (scored > 0) {
      state = CompletenessState.partial;
    } else {
      state = CompletenessState.empty;
    }
    return Completeness._(state, total, scored, official);
  }

  final CompletenessState state;
  final int total;
  final int scored;
  final int official;

  /// "5 of 7 entered".
  String get counts => '$scored of $total entered';
}
