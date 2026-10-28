import 'package:equatable/equatable.dart';

import 'late_placement_service.dart';

/// The answer to placing a pilot in every round: what happened to each round,
/// and a notice when the recalculation that follows a zero score failed, so
/// the results read as stale.
class LatePlacementResult extends Equatable {
  const LatePlacementResult({required this.rounds, this.recalculationWarning});

  factory LatePlacementResult.fromJson(Map<String, Object?> json) =>
      LatePlacementResult(
        rounds: [
          for (final round in json['rounds']! as List<Object?>)
            RoundPlacement.fromJson(round! as Map<String, Object?>),
        ],
        recalculationWarning: json['recalculation_warning'] as String?,
      );

  final List<RoundPlacement> rounds;

  /// A human-readable notice that the recalculation failed, or null.
  final String? recalculationWarning;

  /// The rounds where the pilot was put in a group.
  Iterable<RoundPlacement> get placed => rounds.where((r) => r.placed);

  /// The rounds already fully scored, where the pilot got a zero.
  Iterable<RoundPlacement> get zeroed => rounds.where((r) => r.zeroed);

  /// The rounds no group could take the pilot in.
  Iterable<RoundPlacement> get skipped =>
      rounds.where((r) => r.skippedReason != null);

  Map<String, Object?> toJson() => {
    'rounds': [for (final round in rounds) round.toJson()],
    'recalculation_warning': recalculationWarning,
  };

  @override
  List<Object?> get props => [rounds, recalculationWarning];
}
