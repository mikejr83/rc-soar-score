import 'package:equatable/equatable.dart';

import '../models/participants/contest_participation.dart';

/// The answer to a participation update: the stored participation, and a
/// notice when the recalculation that follows a changed retirement failed, so
/// the results read as stale.
class ParticipationUpdateResult extends Equatable {
  const ParticipationUpdateResult({
    required this.participation,
    this.recalculationWarning,
  });

  /// The participation's own JSON with `recalculation_warning` beside it, so
  /// a caller that only reads the participation still can.
  factory ParticipationUpdateResult.fromJson(Map<String, Object?> json) =>
      ParticipationUpdateResult(
        participation: ContestParticipation.fromJson(json),
        recalculationWarning: json['recalculation_warning'] as String?,
      );

  final ContestParticipation participation;

  /// A human-readable notice that the recalculation failed, or null.
  final String? recalculationWarning;

  Map<String, Object?> toJson() => {
    ...participation.toJson(),
    'recalculation_warning': recalculationWarning,
  };

  @override
  List<Object?> get props => [participation, recalculationWarning];
}
