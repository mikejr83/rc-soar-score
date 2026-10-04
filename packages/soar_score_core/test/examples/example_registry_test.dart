import 'package:test/test.dart';

import '../support/example_registry.dart';

void main() {
  group('ExampleRegistry', () {
    test('looks up registered entities and rejects duplicates', () {
      final registry = ExampleRegistry()..register('Team', (j) => j);
      expect(registry['Team'], isNotNull);
      expect(registry['Role'], isNull);
      expect(registry.entities, ['Team']);
      expect(() => registry.register('Team', (j) => j), throwsStateError);
    });
  });
}
