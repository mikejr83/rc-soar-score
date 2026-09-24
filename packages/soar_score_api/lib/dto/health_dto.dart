import 'package:json_annotation/json_annotation.dart';

part 'health_dto.g.dart';

/// Response payload of the server's public `GET /health` endpoint.
///
/// The field names and values match the payload produced by
/// `soar_score_server`'s health handler (ticket 003).
@JsonSerializable()
class HealthDto {
  const HealthDto({
    required this.name,
    required this.displayName,
    required this.version,
    this.schemaRevision,
  });

  /// Machine-oriented server name (e.g. `soar_score_server`).
  final String name;

  /// Human-readable server display name (e.g. `Soar Score API Server`).
  final String displayName;

  /// Semantic version of the running server.
  final String version;

  /// Last-applied database schema revision (drift-managed).
  final int? schemaRevision;

  factory HealthDto.fromJson(Map<String, dynamic> json) =>
      _$HealthDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HealthDtoToJson(this);

  @override
  bool operator ==(Object other) =>
      other is HealthDto &&
      other.name == name &&
      other.displayName == displayName &&
      other.version == version &&
      other.schemaRevision == schemaRevision;

  @override
  int get hashCode =>
      Object.hash(name, displayName, version, schemaRevision);

  @override
  String toString() =>
      'HealthDto(name: $name, displayName: $displayName, version: $version, schemaRevision: $schemaRevision)';
}
