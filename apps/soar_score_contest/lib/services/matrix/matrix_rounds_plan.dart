import 'package:soar_score_core/soar_score_core.dart';

/// Which action of the Matrix page a director asked for.
enum MatrixIntent {
  /// Draw more rounds after the last one.
  addRounds,

  /// Draw the rounds without scores again.
  redraw;

  /// The value of the `action` query parameter of the Matrix page.
  String get query => switch (this) {
    addRounds => 'add',
    redraw => 'redraw',
  };

  static MatrixIntent? fromQuery(String? value) => switch (value) {
    'add' => addRounds,
    'redraw' => redraw,
    _ => null,
  };
}

/// Why a redraw of the unscored rounds is not allowed.
enum RedrawBlockKind { allScored, roundLocked, groupLocked }

/// What adding rounds and redrawing can do to a drawn matrix: where a redraw
/// starts (the first round after the last one with scores), how many rounds
/// and groups it replaces, and why it is not allowed when it is not.
class MatrixRoundsPlan {
  const MatrixRoundsPlan._({
    required this.lastRound,
    required this.firstUnscored,
    required this.groupsPerRound,
    required this.lastGroups,
    required this.hasScores,
    this.blockKind,
    this.blockRound,
  });

  /// Reads [matrix].
  factory MatrixRoundsPlan.of(CurrentMatrix matrix) {
    final rounds = matrix.rounds.where((round) => round.isCurrent).toList()
      ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    final scoredBy = {
      for (final progress in matrix.progress) progress.roundId: progress.scored,
    };
    var lastScored = 0;
    for (final round in rounds) {
      if ((scoredBy[round.id] ?? 0) > 0) {
        lastScored = round.ordinal;
      }
    }
    final last = rounds.isEmpty ? 0 : rounds.last.ordinal;
    final first = lastScored + 1;
    final replaced = [
      for (final round in rounds)
        if (round.ordinal >= first) round,
    ];
    RedrawBlockKind? block;
    int? blockRound;
    if (replaced.isEmpty) {
      block = RedrawBlockKind.allScored;
    } else {
      for (final round in replaced) {
        if (round.status == RoundStatus.locked) {
          block = RedrawBlockKind.roundLocked;
          blockRound = round.ordinal;
          break;
        }
        final locked = matrix.groups.any(
          (group) => group.roundId == round.id && group.isLocked,
        );
        if (locked) {
          block = RedrawBlockKind.groupLocked;
          blockRound = round.ordinal;
          break;
        }
      }
    }
    return MatrixRoundsPlan._(
      lastRound: last,
      firstUnscored: first,
      groupsPerRound: replaced.isEmpty ? 0 : replaced.first.groupCount,
      lastGroups: rounds.isEmpty ? 0 : rounds.last.groupCount,
      hasScores: lastScored > 0,
      blockKind: block,
      blockRound: blockRound,
    );
  }

  final int lastRound;

  /// The round a redraw starts at: one past the last round with scores.
  /// Past [lastRound] when every round has scores.
  final int firstUnscored;

  /// Groups in the first round a redraw replaces; 0 when none is replaced.
  final int groupsPerRound;

  /// Groups in the last round, for the groups of added rounds.
  final int lastGroups;

  /// Whether any round has scores.
  final bool hasScores;

  /// Why a redraw is not allowed, or `null` when it is, and the round the
  /// reason names.
  final RedrawBlockKind? blockKind;
  final int? blockRound;

  /// How many rounds a redraw replaces.
  int get unscoredRounds => lastRound - firstUnscored + 1;
}
