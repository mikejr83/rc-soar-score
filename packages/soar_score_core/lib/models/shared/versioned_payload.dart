import 'package:equatable/equatable.dart';

/// A payload tagged with the schema version that wrote it, so an older
/// installation's mutation can still be decoded.
class VersionedPayload extends Equatable {
  VersionedPayload({required this.version, required Map<String, Object?> data})
    : data = Map.unmodifiable(data) {
    if (version < 1) {
      throw ArgumentError.value(version, 'version', 'must be at least 1');
    }
  }

  factory VersionedPayload.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    final data = json['data'];
    if (version is! int || data is! Map<String, Object?>) {
      throw const FormatException('expected {version: int, data: object}');
    }
    return VersionedPayload(version: version, data: data);
  }

  /// Schema version of [data].
  final int version;

  /// The entity state or delta.
  final Map<String, Object?> data;

  Map<String, Object?> toJson() => {'version': version, 'data': data};

  @override
  List<Object?> get props => [version, data];
}

/// Decodes the payload of one entity type at one schema version.
typedef PayloadDecoder<T> = T Function(Map<String, Object?> data);

/// Maps `(entityType, version)` to a [PayloadDecoder].
class PayloadDecoderRegistry {
  final Map<(String, int), PayloadDecoder<Object>> _decoders = {};

  /// Registers [decoder]; a duplicate registration is a programming error.
  void register(
    String entityType,
    int version,
    PayloadDecoder<Object> decoder,
  ) {
    final key = (entityType, version);
    if (_decoders.containsKey(key)) {
      throw StateError('decoder already registered for $entityType v$version');
    }
    _decoders[key] = decoder;
  }

  /// Decodes [payload] for [entityType]; throws [UnsupportedError] when no
  /// decoder is registered for its version.
  Object decode(String entityType, VersionedPayload payload) {
    final decoder = _decoders[(entityType, payload.version)];
    if (decoder == null) {
      throw UnsupportedError(
        'no decoder for $entityType at schema version ${payload.version}',
      );
    }
    return decoder(payload.data);
  }
}
