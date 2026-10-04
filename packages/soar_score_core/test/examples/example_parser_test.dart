import 'package:test/test.dart';

import '../support/example_parser.dart';
import '../support/example_registry.dart';

const _doc = '''
# Title

## Team

Prose.

```json
{"id": "a", "revision": 0}
```

## Role

```json
[{"id": "b"}, {"id": "c"}]
```

## Results table

| a | b |

## Team

```json
{"id": "d"}
```
''';

void main() {
  group('parseExampleRows', () {
    test('reads objects and arrays under their heading', () {
      final rows = parseExampleRows(_doc, file: 'f.md');
      expect(rows.map((r) => '${r.entity}:${r.json['id']}'), [
        'Team:a',
        'Role:b',
        'Role:c',
        'Team:d',
      ]);
    });

    test('numbers rows per entity across blocks', () {
      final rows = parseExampleRows(_doc, file: 'f.md');
      expect(rows.where((r) => r.entity == 'Team').map((r) => r.index), [0, 1]);
      expect(rows.where((r) => r.entity == 'Role').map((r) => r.index), [0, 1]);
    });

    test('rejects malformed input', () {
      expect(
        () => parseExampleRows('```json\n{}\n```', file: 'f.md'),
        throwsFormatException,
      );
      expect(
        () => parseExampleRows('## A\n```json\n{', file: 'f.md'),
        throwsFormatException,
      );
      expect(
        () => parseExampleRows('## A\n```json\n[1]\n```', file: 'f.md'),
        throwsFormatException,
      );
      expect(
        () => parseExampleRows('## A\n```json\nnope\n```', file: 'f.md'),
        throwsFormatException,
      );
    });
  });

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
