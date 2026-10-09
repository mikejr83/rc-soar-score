import 'package:equatable/equatable.dart';

import '../models/contest/contest.dart';
import '../models/scores/official_score.dart';
import '../models/scores/score_placeholder.dart';
import 'calculated_flight.dart';

/// The outcome of a director's score entry: the official score that was
/// stored, the placeholder in its new state, the contest as it is after the
/// entry (the first score moves it to `Running`) and the calculated flight.
///
/// [recalculationWarning] is set when the recalculation that followed the
/// entry failed even after a single retry (ticket 297). The score itself is
/// stored and the results read as stale; the warning tells the director the
/// results are not up to date. It is null when the recalculation succeeded,
/// or when it was not attempted.
class ScoreEntryResult extends Equatable {
  const ScoreEntryResult({
    required this.officialScore,
    required this.placeholder,
    required this.contest,
    required this.calculated,
    this.recalculationWarning,
  });

  factory ScoreEntryResult.fromJson(Map<String, Object?> json) =>
      ScoreEntryResult(
        officialScore: OfficialScore.fromJson(
          json['official_score']! as Map<String, Object?>,
        ),
        placeholder: ScorePlaceholder.fromJson(
          json['placeholder']! as Map<String, Object?>,
        ),
        contest: Contest.fromJson(json['contest']! as Map<String, Object?>),
        calculated: CalculatedFlight.fromJson(
          json['calculated']! as Map<String, Object?>,
        ),
        recalculationWarning: json['recalculation_warning'] as String?,
      );

  final OfficialScore officialScore;
  final ScorePlaceholder placeholder;
  final Contest contest;
  final CalculatedFlight calculated;

  /// A human-readable notice that the post-entry recalculation failed, or
  /// null when it succeeded or was not run.
  final String? recalculationWarning;

  Map<String, Object?> toJson() => {
    'official_score': officialScore.toJson(),
    'placeholder': placeholder.toJson(),
    'contest': contest.toJson(),
    'calculated': calculated.toJson(),
    'recalculation_warning': recalculationWarning,
  };

  @override
  List<Object?> get props => [
    officialScore,
    placeholder,
    contest,
    calculated,
    recalculationWarning,
  ];
}