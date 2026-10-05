import 'package:equatable/equatable.dart';

import '../../enums/group_score_mode.dart';
import '../../enums/rounding_mode.dart';

/// Contest options that shape the group score.
class GroupScoreOptions extends Equatable {
  GroupScoreOptions({
    this.mode = GroupScoreMode.normalized,
    this.roundingMode = RoundingMode.round,
    this.decimalPlaces = 1,
  }) {
    if (decimalPlaces < 0 || decimalPlaces > 3) {
      throw ArgumentError.value(
        decimalPlaces,
        'decimalPlaces',
        'must be 0 to 3',
      );
    }
  }

  final GroupScoreMode mode;
  final RoundingMode roundingMode;
  final int decimalPlaces;

  @override
  List<Object?> get props => [mode, roundingMode, decimalPlaces];
}
