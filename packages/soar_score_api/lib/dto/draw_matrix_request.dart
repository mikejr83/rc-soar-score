import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'draw_matrix_request.g.dart';

/// Body of `POST /api/v1/contests/{id}/matrix/draws`.
///
/// The caller generates [id] (a UUIDv7, the new matrix revision's id), so
/// repeating the request returns the matrix it drew. [randomSeed], an
/// unsigned 32-bit integer, makes the draw reproducible; the server picks one
/// when it is null.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class DrawMatrixRequest {
  const DrawMatrixRequest({
    required this.id,
    required this.rounds,
    required this.groupsPerRound,
    this.randomSeed,
  });

  factory DrawMatrixRequest.fromJson(Map<String, dynamic> json) =>
      _$DrawMatrixRequestFromJson(json);

  final Id id;
  final int rounds;
  final int groupsPerRound;
  final int? randomSeed;

  Map<String, dynamic> toJson() => _$DrawMatrixRequestToJson(this);
}
