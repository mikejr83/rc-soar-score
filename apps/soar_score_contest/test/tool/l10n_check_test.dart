import 'package:flutter_test/flutter_test.dart';

import '../../tool/l10n_check.dart';

void main() {
  final source = {
    '@@locale': 'en',
    'hello': 'Hello {name}',
    '@hello': {
      'description': 'Greets someone.',
      'placeholders': {
        'name': {'type': 'String'},
      },
    },
    'count': '{n, plural, one{1 pilot} other{{n} pilots}}',
    'plain': 'Save',
  };

  List<ArbProblem> check(Map<String, Object?> translation) =>
      checkTranslation(source: source, translation: translation, locale: 'fr');

  List<String> errors(Map<String, Object?> translation) => [
    for (final p in check(translation))
      if (p.isError) p.message,
  ];

  group('checkTranslation', () {
    test('accepts a complete translation', () {
      final problems = check({
        '@@locale': 'fr',
        'hello': 'Bonjour {name}',
        'count': '{n, plural, one{1 pilote} other{{n} pilotes}}',
        'plain': 'Enregistrer',
      });

      expect(problems, isEmpty);
    });

    test('rejects a changed placeholder', () {
      expect(
        errors({'@@locale': 'fr', 'hello': 'Bonjour {nom}'}),
        contains(contains('"hello" must use the placeholders {name}')),
      );
    });

    test('rejects a lost plural', () {
      expect(
        errors({'@@locale': 'fr', 'count': '{n} pilotes'}),
        contains(contains('plural or select')),
      );
    });

    test('rejects unbalanced braces and unknown keys', () {
      final found = errors({
        '@@locale': 'fr',
        'hello': 'Bonjour {name',
        'nope': 'x',
      });

      expect(found, contains(contains('unbalanced')));
      expect(found, contains(contains('"nope" is not a message')));
    });

    test('needs the right locale', () {
      expect(
        errors({'hello': 'Bonjour {name}'}),
        contains(contains('missing')),
      );
      expect(
        errors({'@@locale': 'de', 'hello': 'Hallo {name}'}),
        contains(contains('"de"')),
      );
    });

    test('warns about gaps without failing', () {
      final problems = check({'@@locale': 'fr', 'plain': 'Save'});

      expect(problems.where((p) => p.isError), isEmpty);
      expect(
        problems.map((p) => p.message),
        containsAll([
          contains('"plain" is the same as English'),
          contains('"hello" is missing'),
        ]),
      );
    });
  });

  group('buildTemplate', () {
    test('lists every message with its description', () {
      final text = buildTemplate(
        source: source,
        existing: null,
        locale: 'fr-FR',
      );
      final template = parseArb(text);

      expect(template['@@locale'], 'fr_FR');
      expect(template['hello'], 'Hello {name}');
      expect(template['@hello'], source['@hello']);
      expect(
        checkTranslation(
          source: source,
          translation: template,
          locale: 'fr-FR',
        ).where((p) => p.isError),
        isEmpty,
      );
    });

    test('keeps an existing translation', () {
      final text = buildTemplate(
        source: source,
        existing: {'plain': 'Enregistrer'},
        locale: 'fr',
      );

      expect(parseArb(text)['plain'], 'Enregistrer');
      expect(parseArb(text)['hello'], 'Hello {name}');
    });
  });
}
