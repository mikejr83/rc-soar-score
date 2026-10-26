import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'draw_status_dto.g.dart';

/// Where a draw is, as answered by
/// `GET /api/v1/contests/{id}/matrix/draws/{drawId}` and by cancelling it.
///
/// [id] is the draw's matrix revision id, the one in its request. While the
/// draw [running], [percent] (0 to 99) says how far the improvement has come
/// and [seed] which of the [seedCount] seeds it is on, counting from 1.
@JsonSerializable(checked: true, fieldRename: FieldRename.snake)
@IdConverter()
class DrawStatusDto {
  const DrawStatusDto({
    required this.id,
    required this.state,
    required this.percent,
    required this.seed,
    required this.seedCount,
  });

  factory DrawStatusDto.fromJson(Map<String, dynamic> json) =>
      _$DrawStatusDtoFromJson(json);

  /// The status of [job].
  factory DrawStatusDto.of(DrawJobStatus job) => DrawStatusDto(
    id: job.id,
    state: job.state,
    percent: job.progress.percent,
    seed: job.progress.seed,
    seedCount: job.progress.seedCount,
  );

  final Id id;
  final DrawJobState state;
  final int percent;
  final int seed;
  final int seedCount;

  bool get running => state == DrawJobState.running;

  Map<String, dynamic> toJson() => _$DrawStatusDtoToJson(this);
}
