import 'package:equatable/equatable.dart';

/// How a round tile of the progress card reads.
enum ProgressTileState {
  /// Every slot has a score.
  scored,

  /// A round behind the latest scored round that still lacks scores,
  /// including one that was never flown.
  missing,

  /// The latest scored round, not yet fully scored.
  inProgress,

  /// A round ahead of the latest scored round, with no scores.
  notFlown,

  /// A round of a seeded contest that is planned but not drawn yet.
  notDrawn,
}

/// One round of the progress card.
class ProgressTile extends Equatable {
  const ProgressTile({
    required this.ordinal,
    required this.state,
    this.scored = 0,
    this.total = 0,
  });

  final int ordinal;
  final ProgressTileState state;

  /// Slots with a score; zero for a round that is not drawn.
  final int scored;

  /// Slots that can be scored; zero for a round that is not drawn.
  final int total;

  /// How many scores a [ProgressTileState.missing] round lacks.
  int get missing => state == ProgressTileState.missing ? total - scored : 0;

  @override
  List<Object?> get props => [ordinal, state, scored, total];
}
