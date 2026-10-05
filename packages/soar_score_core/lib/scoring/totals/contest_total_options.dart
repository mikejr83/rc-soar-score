import 'package:equatable/equatable.dart';

/// Contest options that shape the contest total.
class ContestTotalOptions extends Equatable {
  ContestTotalOptions({List<int> dropAfterRounds = const []})
    : dropAfterRounds = List.unmodifiable(dropAfterRounds) {
    if (this.dropAfterRounds.length > 2) {
      throw ArgumentError.value(
        dropAfterRounds,
        'dropAfterRounds',
        'at most 2',
      );
    }
    for (var i = 0; i < this.dropAfterRounds.length; i++) {
      final round = this.dropAfterRounds[i];
      if (round < 1 || (i > 0 && round <= this.dropAfterRounds[i - 1])) {
        throw ArgumentError.value(
          dropAfterRounds,
          'dropAfterRounds',
          'must be ascending integers of 1 or more',
        );
      }
    }
  }

  /// `[4]` drops each pilot's lowest round once round 4 is complete; `[4, 8]`
  /// drops a second once round 8 is complete. Empty means no drops.
  final List<int> dropAfterRounds;

  @override
  List<Object?> get props => [dropAfterRounds];
}
