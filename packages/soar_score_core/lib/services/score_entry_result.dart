import 'package:equatable/equatable.dart';

import '../models/contest/contest.dart';
import '../models/scores/official_score.dart';
import '../models/scores/score_placeholder.dart';
import 'calculated_flight.dart';

/// The outcome of a director's score entry: the official score that was
/// stored, the placeholder in its new state, the contest as it is after the
/// entry (the first score moves it to `Running`) and the calculated flight.
class ScoreEntryResult extends Equatable {
  const ScoreEntryResult({
    required this.officialScore,
    required this.placeholder,
    required this.contest,
    required this.calculated,
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
      );

  final OfficialScore officialScore;
  final ScorePlaceholder placeholder;
  final Contest contest;
  final CalculatedFlight calculated;

  Map<String, Object?> toJson() => {
    'official_score': officialScore.toJson(),
    'placeholder': placeholder.toJson(),
    'contest': contest.toJson(),
    'calculated': calculated.toJson(),
  };

  @override
  List<Object?> get props => [officialScore, placeholder, contest, calculated];
}
