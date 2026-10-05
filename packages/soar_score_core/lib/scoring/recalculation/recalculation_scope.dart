import 'package:equatable/equatable.dart';

import 'config_change.dart';

/// What triggered a recalculation.
enum RecalculationReason {
  configChange,
  matrixChange,
  scoreChange,
  calculationVersionChange,
}

/// How much of the contest has to be recomputed.
///
/// Results from [fromRound] onward are recomputed; earlier rounds keep their
/// stored values. A change to a calculation-affecting setting, the matrix
/// or the calculation version recomputes everything (round 1 onward). A
/// changed official score recomputes its round and every standing after it.
class RecalculationScope extends Equatable {
  const RecalculationScope._(this.reason, this.fromRound);

  /// A full recalculation, or null when [change] needs none.
  static RecalculationScope? forConfigChange(ConfigChange change) =>
      change.requiresRecalculation
      ? const RecalculationScope._(RecalculationReason.configChange, 1)
      : null;

  /// From the earliest round whose assignments changed.
  factory RecalculationScope.forMatrixChange(int earliestAffectedRound) {
    _checkRound(earliestAffectedRound);
    return RecalculationScope._(
      RecalculationReason.matrixChange,
      earliestAffectedRound,
    );
  }

  /// From the round of the official score that changed.
  factory RecalculationScope.forScoreChange(int round) {
    _checkRound(round);
    return RecalculationScope._(RecalculationReason.scoreChange, round);
  }

  /// A full recalculation when a stored result's version differs from the
  /// current one, otherwise null.
  static RecalculationScope? forCalculationVersion({
    required String storedVersion,
    required String currentVersion,
  }) => storedVersion == currentVersion
      ? null
      : const RecalculationScope._(
          RecalculationReason.calculationVersionChange,
          1,
        );

  final RecalculationReason reason;

  /// The first round to recompute; 1 means everything.
  final int fromRound;

  bool get isFull => fromRound == 1;

  static void _checkRound(int round) {
    if (round < 1) throw ArgumentError.value(round, 'round', 'starts at 1');
  }

  @override
  List<Object?> get props => [reason, fromRound];
}
