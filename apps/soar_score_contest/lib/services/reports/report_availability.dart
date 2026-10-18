import 'report_kind.dart';
import 'reports_facts.dart';

/// Where a reason or warning on a card sends the director.
enum ReportDestination { scoring, matrix }

/// A link that fixes or explains a reason or warning.
class ReportAction {
  const ReportAction(this.label, this.destination, {this.round});

  final String label;
  final ReportDestination destination;

  /// The round to open the scoring page at, when known.
  final int? round;
}

/// A warning on an available card: the report can still be opened.
class ReportNote {
  const ReportNote({required this.lead, required this.text, this.action});

  /// The bold first words, so the note never relies on colour.
  final String lead;
  final String text;
  final ReportAction? action;
}

/// Whether a report can be produced now and what the card says about it.
class ReportAvailability {
  const ReportAvailability._({this.reason, this.action, this.notes = const []});

  /// Unavailable: the Open button is disabled and [reason] sits beside it.
  const ReportAvailability.unavailable(String reason, ReportAction action)
    : this._(reason: reason, action: action);

  /// Available, with the [notes] shown on the card.
  const ReportAvailability.available([List<ReportNote> notes = const []])
    : this._(notes: notes);

  /// Why the report cannot be opened; `null` when it can.
  final String? reason;
  final ReportAction? action;
  final List<ReportNote> notes;

  bool get isAvailable => reason == null;

  static const _noScores = ReportAction(
    'Open Scoring',
    ReportDestination.scoring,
  );
  static const _noMatrix = ReportAction(
    'Open Matrix',
    ReportDestination.matrix,
  );
  static const _openMatrix = ReportAction(
    'Open Matrix',
    ReportDestination.matrix,
  );

  /// The availability of [kind] for [facts].
  static ReportAvailability of(ReportKind kind, ReportsFacts facts) {
    if (kind.needsScores) {
      if (!facts.hasScores) {
        return const ReportAvailability.unavailable(
          'No scores have been entered yet.',
          _noScores,
        );
      }
      return ReportAvailability.available(_scoreNotes(facts));
    }
    if (!facts.hasMatrix) {
      return const ReportAvailability.unavailable(
        'The matrix has not been drawn.',
        _noMatrix,
      );
    }
    return ReportAvailability.available([
      if (facts.configDrift.isNotEmpty)
        const ReportNote(
          lead: 'Configuration changed',
          text:
              'since the matrix was drawn. This report shows the drawn '
              'matrix.',
          action: _openMatrix,
        ),
      ?_undrawnRounds(facts),
    ]);
  }

  static List<ReportNote> _scoreNotes(ReportsFacts facts) {
    final standing = facts.standing;
    final first = standing.firstMissingRound;
    final parts = <String>[];
    if (first != null) {
      final count = standing.missingByRound[first]!;
      parts.add(
        '$count ${count == 1 ? 'pilot has' : 'pilots have'} no score in '
        'round $first.',
      );
      final others = standing.missingByRound.length - 1;
      if (others > 0) {
        parts.add(
          '$others other ${others == 1 ? 'round is' : 'rounds are'} '
          'also missing scores.',
        );
      }
    }
    if (standing.unofficial > 0) {
      final count = standing.unofficial;
      parts.add(
        '$count ${count == 1 ? 'score is' : 'scores are'} not official yet.',
      );
    }
    if (parts.isEmpty) {
      return const [];
    }
    return [
      ReportNote(
        lead: 'Preliminary:',
        text: parts.join(' '),
        action: ReportAction(
          'Open Scoring',
          ReportDestination.scoring,
          round: first,
        ),
      ),
    ];
  }

  /// "Rounds 7 and 8 are not drawn yet", for a seeded contest that has drawn
  /// only some of its intended rounds.
  static ReportNote? _undrawnRounds(ReportsFacts facts) {
    final intended = facts.intendedTotalRounds;
    final drawn = facts.roundCount;
    if (!facts.isSeeded || intended == null || drawn >= intended) {
      return null;
    }
    final undrawn = drawn + 1 == intended
        ? 'Round $intended is'
        : intended == drawn + 2
        ? 'Rounds ${drawn + 1} and $intended are'
        : 'Rounds ${drawn + 1} to $intended are';
    final drawnText = drawn == 1 ? 'Round 1' : 'Rounds 1 to $drawn';
    return ReportNote(
      lead: '$drawnText drawn.',
      text:
          '$undrawn not drawn yet. Cards for a redrawn round must be '
          'reprinted.',
      action: _openMatrix,
    );
  }
}
