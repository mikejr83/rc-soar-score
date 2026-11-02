import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'enter_scores_request.g.dart';

/// Body of `POST /api/v1/contests/{id}/scores/bulk`: the scores of several
/// slots, entered by the director as official scores in one request.
///
/// Each entry has the fields of an [EnterScoreRequest] plus its
/// [assignmentId], and its own `client_mutation_id`, so repeating the request
/// returns what each entry made the first time. At most [maxEntries] entries,
/// for different slots.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
  explicitToJson: true,
)
class EnterScoresRequest {
  const EnterScoresRequest({required this.entries});

  factory EnterScoresRequest.fromJson(Map<String, dynamic> json) =>
      _$EnterScoresRequestFromJson(json);

  /// The most entries one request takes.
  static const int maxEntries = 100;

  final List<EnterScoresEntry> entries;

  Map<String, dynamic> toJson() => _$EnterScoresRequestToJson(this);
}

/// One entry of an [EnterScoresRequest].
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class EnterScoresEntry {
  const EnterScoresEntry({
    required this.assignmentId,
    required this.clientMutationId,
    required this.baseScoreRevision,
    required this.components,
    this.reason,
  });

  factory EnterScoresEntry.fromJson(Map<String, dynamic> json) =>
      _$EnterScoresEntryFromJson(json);

  final Id assignmentId;
  final String clientMutationId;
  final int baseScoreRevision;
  final Map<String, Object?> components;
  final String? reason;

  Map<String, dynamic> toJson() => _$EnterScoresEntryToJson(this);
}

/// The answer to an [EnterScoresRequest] (200): one outcome per entry, in
/// order, each either the stored entry or the refusal that entry would have
/// got alone.
///
/// [recalculationWarning] is the notice of the single recalculation that
/// followed the stored entries, or null when it succeeded (or nothing was
/// stored).
class EnterScoresResult {
  const EnterScoresResult({required this.results, this.recalculationWarning});

  factory EnterScoresResult.fromJson(Map<String, Object?> json) =>
      EnterScoresResult(
        results: [
          for (final item in json['results']! as List<Object?>)
            BulkScoreOutcome.fromJson(item! as Map<String, Object?>),
        ],
        recalculationWarning: json['recalculation_warning'] as String?,
      );

  final List<BulkScoreOutcome> results;
  final String? recalculationWarning;

  Map<String, Object?> toJson() => {
    'results': [for (final outcome in results) outcome.toJson()],
    'recalculation_warning': recalculationWarning,
  };
}
