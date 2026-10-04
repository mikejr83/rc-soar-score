/// Decodes an example row into a model and encodes it back.
typedef RoundTrip = Map<String, Object?> Function(Map<String, Object?> json);

/// Maps an entity name to its round-trip function.
///
/// Each model PR registers its entities here so the example harness exercises
/// them; entities without a registration are reported as unregistered.
class ExampleRegistry {
  final Map<String, RoundTrip> _roundTrips = {};

  /// Registers [roundTrip], normally `(json) => Model.fromJson(json).toJson()`.
  void register(String entity, RoundTrip roundTrip) {
    if (_roundTrips.containsKey(entity)) {
      throw StateError('$entity is already registered');
    }
    _roundTrips[entity] = roundTrip;
  }

  /// The round trip for [entity], or null when none is registered.
  RoundTrip? operator [](String entity) => _roundTrips[entity];

  /// Registered entity names.
  Iterable<String> get entities => _roundTrips.keys;
}
