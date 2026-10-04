import 'example_registry.dart';

/// The entities the example harness can round-trip.
///
/// Each model PR adds its entities here, for example:
/// `registry.register('Team', (j) => Team.fromJson(j).toJson());`
ExampleRegistry buildExampleRegistry() => ExampleRegistry();
