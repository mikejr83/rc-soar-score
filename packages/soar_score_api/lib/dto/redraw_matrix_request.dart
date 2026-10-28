import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'redraw_matrix_request.g.dart';

/// Body of `POST /api/v1/contests/{id}/matrix/redraws`.
///
/// Draws [rounds] rounds of [groupsPerRound] groups from round [firstRound]
/// on, as a new matrix revision [id]. With [firstRound] one past the last
/// round the matrix is extended; otherwise every round from [firstRound] to
/// the end is replaced, which needs those rounds to have no scores. The
/// caller generates [id] (a UUIDv7), so repeating the request returns the
/// matrix it drew. [randomSeed], [attemptsPerRound] and [seedCount] are as in
/// [DrawMatrixRequest]. [reason] is optional.
///
/// [baseMatrixRevision] is the number of the latest revision the caller drew
/// from; when it is no longer the newest, the redraw is refused with
/// `stale_matrix` before anything is drawn. [preview] runs the same draw but
/// stores nothing and answers the fairness of the candidate instead of the
/// matrix.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class RedrawMatrixRequest {
  const RedrawMatrixRequest({
    required this.id,
    required this.firstRound,
    required this.rounds,
    required this.groupsPerRound,
    this.randomSeed,
    this.attemptsPerRound,
    this.seedCount,
    this.reason,
    required this.baseMatrixRevision,
    this.preview,
  });

  factory RedrawMatrixRequest.fromJson(Map<String, dynamic> json) =>
      _$RedrawMatrixRequestFromJson(json);

  final Id id;
  final int firstRound;
  final int rounds;
  final int groupsPerRound;
  final int? randomSeed;
  final int? attemptsPerRound;
  final int? seedCount;
  final String? reason;
  final int baseMatrixRevision;

  /// Whether to draw without persisting and answer a [RedrawPreview].
  final bool? preview;

  Map<String, dynamic> toJson() => _$RedrawMatrixRequestToJson(this);
}
