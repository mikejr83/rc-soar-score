import 'package:equatable/equatable.dart';

/// The answer to removing a participant: how many matrix rows went with them,
/// and a notice when the recalculation that follows failed.
class ParticipationRemoveResult extends Equatable {
  const ParticipationRemoveResult({
    this.matrixRowsRemoved = 0,
    this.recalculationWarning,
  });

  factory ParticipationRemoveResult.fromJson(Map<String, Object?> json) =>
      ParticipationRemoveResult(
        matrixRowsRemoved: json['matrix_rows_removed'] as int? ?? 0,
        recalculationWarning: json['recalculation_warning'] as String?,
      );

  /// How many matrix rows (a pilot's place in a round) were removed. When
  /// this is above zero the draw no longer includes the pilot and needs
  /// redoing.
  final int matrixRowsRemoved;

  /// A human-readable notice that the recalculation failed, or null.
  final String? recalculationWarning;

  Map<String, Object?> toJson() => {
    'matrix_rows_removed': matrixRowsRemoved,
    'recalculation_warning': recalculationWarning,
  };

  @override
  List<Object?> get props => [matrixRowsRemoved, recalculationWarning];
}
