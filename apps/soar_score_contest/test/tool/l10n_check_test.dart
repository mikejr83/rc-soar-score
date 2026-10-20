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
        contains(contains('must keep the {n, plural, ...} choice')),
      );
    });

    test('rejects a plural without other or a changed selector', () {
      expect(
        errors({'@@locale': 'fr', 'count': '{n, plural, one{1 pilote}}'}),
        contains(contains('needs an "other" option')),
      );
      expect(
        errors({
          '@@locale': 'fr',
          'count': '{m, plural, one{1 pilote} other{{m} pilotes}}',
        }),
        contains(contains('must keep the {n, plural, ...} choice')),
      );
      expect(
        errors({
          '@@locale': 'fr',
          'count': '{n, select, one{1 pilote} other{{n} pilotes}}',
        }),
        isNotEmpty,
      );
    });

    test('allows the extra plural categories a language needs', () {
      expect(
        errors({
          '@@locale': 'fr',
          'count':
              '{n, plural, one{1 pilote} few{{n} pilotes} other{{n} pilotes}}',
        }),
        isEmpty,
      );
    });

    test('keeps exact matches and every select option', () {
      final strict = {
        'a': '{n, plural, =0{none} one{1} other{{n}}}',
        'b': '{v, select, x{X} y{Y} other{Z}}',
      };
      final found = [
        for (final p in checkTranslation(
          source: strict,
          translation: {
            '@@locale': 'fr',
            'a': '{n, plural, one{1} other{{n}}}',
            'b': '{v, select, x{X} other{Z}}',
          },
          locale: 'fr',
        ))
          if (p.isError) p.message,
      ];

      expect(found, contains(contains('must keep the "=0" option')));
      expect(found, contains(contains('must keep the "y" option')));
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

    test('accepts single-word plural and select branches', () {
      final words = {
        'count': '{n, plural, one{pilot} other{{n} pilots}}',
        'kind': '{v, select, a{one} other{many}}',
      };
      final found = checkTranslation(
        source: words,
        translation: {
          '@@locale': 'fr',
          'count': '{n, plural, one{pilote} other{{n} pilotes}}',
          'kind': '{v, select, a{un} other{plusieurs}}',
        },
        locale: 'fr',
      );

      expect(found.where((p) => p.isError), isEmpty);
    });

    test('rejects balanced but malformed brace expressions', () {
      expect(
        errors({'@@locale': 'fr', 'plain': 'Panneaux {}'}),
        contains(contains('malformed expression')),
      );
      expect(
        errors({'@@locale': 'fr', 'plain': 'A {1x} b'}),
        contains(contains('malformed expression')),
      );
      expect(
        errors({'@@locale': 'fr', 'count': '{n, plural, one 1 other{{n}}}'}),
        isNotEmpty,
      );
    });

    test('rejects an empty or blank translation', () {
      expect(
        errors({'@@locale': 'fr', 'plain': '  '}),
        contains(contains('"plain" is empty')),
      );
    });

    test('takes the locale from a recognized file name first', () {
      expect(expectedLocale(path: 'x/app_fr_FR.arb', declared: 'de'), 'fr_FR');
      expect(expectedLocale(path: 'my-file.arb', declared: 'de'), 'de');
      expect(
        expectedLocale(explicit: 'es', path: 'app_fr.arb', declared: 'de'),
        'es',
      );
      expect(expectedLocale(path: 'my-file.arb'), 'en');
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
