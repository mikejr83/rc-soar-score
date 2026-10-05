import 'package:equatable/equatable.dart';

/// A pilot's raw and group score for one group.
class GroupScoreEntry extends Equatable {
  const GroupScoreEntry({
    required this.pilotId,
    required this.rawScore,
    required this.groupScore,
  });

  final String pilotId;

  /// The unrounded raw score.
  final double rawScore;

  /// The group score after the single final rounding or truncation.
  final double groupScore;

  @override
  List<Object?> get props => [pilotId, rawScore, groupScore];
}
