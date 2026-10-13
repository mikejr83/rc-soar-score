import 'package:soar_score_core/soar_score_core.dart';

import 'progress_headline.dart';
import 'progress_lag.dart';
import 'progress_tile.dart';

/// The words of the progress card, kept out of the widgets so they can be
/// tested and so a state is always spelled the same way.
abstract final class ProgressText {
  static const String title = 'Progress';

  static const String emptyTitle = 'No matrix yet';
  static const String emptyBody =
      'Round progress appears here once the matrix is drawn.';

  static const String unavailable = 'Round progress could not be loaded.';
  static const String loading = 'Loading round progress…';

  /// The small caption above the headline.
  static String whereLabel(ProgressHeadline headline) =>
      headline.stage == ProgressStage.finished ? 'Final' : 'Where we are';

  /// The large headline, for example "Round 3 of 8".
  static String whereMain(ProgressHeadline headline) {
    switch (headline.stage) {
      case ProgressStage.inProgress:
        return 'Round ${headline.currentRound} of ${headline.totalRounds}';
      case ProgressStage.finished:
        return headline.allRoundsFlown
            ? 'All ${headline.totalRounds} rounds flown'
            : '${headline.roundsFlown} of ${headline.totalRounds} rounds flown';
      case ProgressStage.noScores:
        return 'No scores yet';
      case ProgressStage.noMatrix:
      case ProgressStage.scoresUnavailable:
        return '';
    }
  }

  /// The quiet line beside the headline, with the time in [zoneId].
  static String whereSub(ProgressHeadline headline, {required String zoneId}) {
    switch (headline.stage) {
      case ProgressStage.inProgress:
        final parts = [
          if (headline.currentGroup != null)
            'Group ${groupLetter(headline.currentGroup!)}'
                '${headline.groupsInCurrentRound == null ? '' : ' of ${headline.groupsInCurrentRound}'}',
          if (headline.latestScoreAt != null)
            'latest accepted score ${clock(headline.latestScoreAt!, zoneId)}',
        ];
        return parts.join(' · ');
      case ProgressStage.finished:
        return _plural(headline.scoreCount, 'score');
      case ProgressStage.noScores:
        final size = headline.groupSizeMin == headline.groupSizeMax
            ? '${headline.groupSizeMax}'
            : '${headline.groupSizeMin} to ${headline.groupSizeMax}';
        return [
          _plural(headline.roundCount, 'round'),
          if (headline.groupCount > 0)
            '${_plural(headline.groupCount, 'group')} of $size',
          if (headline.matrixRevision != null)
            'matrix revision ${headline.matrixRevision}',
        ].join(' · ');
      case ProgressStage.noMatrix:
      case ProgressStage.scoresUnavailable:
        return '';
    }
  }

  /// The informational note under the headline.
  static String lag(ProgressLag lag) =>
      'Round ${lag.roundOrdinal}, group ${groupLetter(lag.groupNumber)}: '
      '${lag.pending} of ${lag.total} pilots haven’t entered scores yet. '
      'That’s normal right after a group lands. They count as missing '
      'only once the round is finished.';

  /// "Round 3".
  static String tileTitle(ProgressTile tile) => 'Round ${tile.ordinal}';

  /// "13/24", or a dash for a round that is not drawn.
  static String tileCount(ProgressTile tile) =>
      tile.state == ProgressTileState.notDrawn
      ? '—'
      : '${tile.scored}/${tile.total}';

  /// The state under the count; never left to colour or icon alone.
  static String tileState(ProgressTile tile) => switch (tile.state) {
    ProgressTileState.scored => 'Scored',
    ProgressTileState.missing => '${tile.missing} missing',
    ProgressTileState.inProgress => 'In progress',
    ProgressTileState.notFlown => 'Not flown',
    ProgressTileState.notDrawn => 'Not drawn',
  };

  /// What assistive technology reads for a tile.
  static String tileLabel(ProgressTile tile) {
    final round = 'Round ${tile.ordinal}';
    switch (tile.state) {
      case ProgressTileState.scored:
        return '$round: Scored, ${tile.scored} of ${tile.total} pilots. '
            'Open in Scoring.';
      case ProgressTileState.missing:
        return '$round: ${_plural(tile.missing, 'score')} missing, '
            '${tile.scored} of ${tile.total} pilots scored. Open in Scoring.';
      case ProgressTileState.inProgress:
        return '$round: In progress, ${tile.scored} of ${tile.total} pilots '
            'scored. Open in Scoring.';
      case ProgressTileState.notFlown:
        return '$round: Not flown. Open in Scoring.';
      case ProgressTileState.notDrawn:
        return '$round: Not drawn yet.';
    }
  }

  /// Group 1 is A.
  static String groupLetter(int group) =>
      group >= 1 && group <= 26 ? String.fromCharCode(0x40 + group) : '$group';

  /// `13:31` for [utc] in [zoneId].
  static String clock(DateTime utc, String zoneId) {
    final t = ContestTime.inZone(utc, zoneId);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  static String _plural(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';
}
