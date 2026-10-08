import 'package:soar_score_core/soar_score_core.dart';

/// Where a round stands, for the header of its matrix column.
enum RoundProgressState {
  notFlown('Not flown'),
  inProgress('In progress'),
  scored('Scored'),
  cancelled('Cancelled');

  const RoundProgressState(this.label);

  final String label;
}

/// A round's progress: its state and how many flights have a score.
///
/// The state follows the counts (none scored is not flown, some is in
/// progress, all is scored); a cancelled round stays cancelled. The lock of a
/// round is separate and does not decide the state.
class RoundProgressView {
  const RoundProgressView({
    required this.state,
    required this.scored,
    required this.total,
  });

  factory RoundProgressView.of(
    RoundStatus status, {
    required int scored,
    required int total,
  }) {
    final state = status == RoundStatus.cancelled
        ? RoundProgressState.cancelled
        : scored <= 0
        ? RoundProgressState.notFlown
        : scored >= total
        ? RoundProgressState.scored
        : RoundProgressState.inProgress;
    return RoundProgressView(state: state, scored: scored, total: total);
  }

  final RoundProgressState state;
  final int scored;
  final int total;

  /// The header text, for example "In progress, 12 of 21 scored".
  String get label => switch (state) {
    RoundProgressState.inProgress => '${state.label}, $scored of $total scored',
    RoundProgressState.scored => '${state.label}, $total of $total',
    _ => state.label,
  };
}
