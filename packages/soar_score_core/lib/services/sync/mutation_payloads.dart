import '../../models/shared/versioned_payload.dart';

/// The shape of `MutationRecord.payload`: a `VersionedPayload` whose data
/// names an `operation` (`save` or `delete`).
class MutationPayload {
  const MutationPayload._({
    required this.isDelete,
    this.entity = const {},
    this.supersedes,
  });

  /// The payload version this build writes and reads.
  static const int version = 1;

  /// A deletion.
  static const MutationPayload delete = MutationPayload._(isDelete: true);

  /// A save of [entity]; [supersedes] is the id of the assignment a `Moved`
  /// assignment replaces.
  factory MutationPayload.save(
    Map<String, Object?> entity, {
    String? supersedes,
  }) => MutationPayload._(
    isDelete: false,
    entity: entity,
    supersedes: supersedes,
  );

  /// Reads [json], throwing a [FormatException] when it is not a payload this
  /// build understands.
  factory MutationPayload.parse(Map<String, Object?> json) {
    final VersionedPayload payload;
    try {
      payload = VersionedPayload.fromJson(json);
    } on ArgumentError catch (e) {
      throw FormatException('${e.message}');
    }
    if (payload.version != version) {
      throw FormatException('payload version ${payload.version} is unknown');
    }
    switch (payload.data['operation']) {
      case 'delete':
        return delete;
      case 'save':
        final entity = payload.data['entity'];
        if (entity is! Map<String, Object?>) {
          throw const FormatException('a save carries the entity');
        }
        final supersedes = payload.data['supersedes'];
        if (supersedes != null && supersedes is! String) {
          throw const FormatException('supersedes must be an id');
        }
        return MutationPayload.save(entity, supersedes: supersedes as String?);
      default:
        throw FormatException('unknown operation ${payload.data['operation']}');
    }
  }

  final bool isDelete;

  /// The entity state of a save; empty for a delete.
  final Map<String, Object?> entity;
  final String? supersedes;

  Map<String, Object?> toJson() => VersionedPayload(
    version: version,
    data: isDelete
        ? const {'operation': 'delete'}
        : {'operation': 'save', 'entity': entity, 'supersedes': ?supersedes},
  ).toJson();
}
