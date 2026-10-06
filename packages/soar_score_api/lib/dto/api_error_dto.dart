import 'package:json_annotation/json_annotation.dart';

part 'api_error_dto.g.dart';

/// The `error` object of every failure body:
/// `{"error": {"code", "message", "requestId"}}`.
@JsonSerializable()
class ApiErrorDto {
  const ApiErrorDto({
    required this.code,
    required this.message,
    this.requestId,
  });

  factory ApiErrorDto.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorDtoFromJson(json);

  /// A short stable name, for example `stale_revision` or `not_found`.
  final String code;
  final String message;
  final String? requestId;

  Map<String, dynamic> toJson() => _$ApiErrorDtoToJson(this);
}
