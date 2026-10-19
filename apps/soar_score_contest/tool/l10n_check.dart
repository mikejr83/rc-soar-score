import 'dart:convert';

/// A problem found in a translation file.
class ArbProblem {
  const ArbProblem(this.message, {this.isError = true});

  final String message;

  /// Errors keep a file out of the app; warnings only point at gaps.
  final bool isError;

  @override
  String toString() => '${isError ? 'error' : 'warning'}: $message';
}

final _placeholder = RegExp(r'\{(\w+)(?:,|\})');

/// Whether [key] is a message (not metadata such as `@@locale` or `@name`).
bool isMessageKey(String key) => !key.startsWith('@');

/// Parses ARB [text] as a JSON object, or throws a [FormatException].
Map<String, Object?> parseArb(String text) {
  final decoded = jsonDecode(text);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('the file is not a JSON object');
  }
  return decoded;
}

Set<String> _placeholders(String message) => {
  for (final match in _placeholder.allMatches(message)) match.group(1)!,
};

/// One `{arg, kind, selector{...} ...}` of a message.
class _Icu {
  _Icu(this.arg, this.kind, this.selectors);

  final String arg;
  final String kind;
  final Set<String> selectors;

  String get id => '$arg,$kind';
}

/// Every plural, select and selectordinal in [message], nested ones included.
/// Returns an empty list for text it cannot read (unbalanced braces are
/// reported separately).
List<_Icu> _icuParts(String message) {
  final found = <_Icu>[];
  void scan(String text) {
    var i = 0;
    while (i < text.length) {
      if (text[i] != '{') {
        i++;
        continue;
      }
      final end = _closing(text, i);
      if (end < 0) return;
      final inner = text.substring(i + 1, end);
      final first = _topLevelComma(inner, 0);
      final second = first < 0 ? -1 : _topLevelComma(inner, first + 1);
      if (second > 0) {
        final arg = inner.substring(0, first).trim();
        final kind = inner.substring(first + 1, second).trim();
        if (kind == 'plural' || kind == 'select' || kind == 'selectordinal') {
          final selectors = <String>{};
          final rest = inner.substring(second + 1);
          var j = 0;
          while (j < rest.length) {
            final open = rest.indexOf('{', j);
            if (open < 0) break;
            final close = _closing(rest, open);
            if (close < 0) break;
            final name = rest.substring(j, open).trim();
            if (!name.startsWith('offset:')) {
              selectors.add(name);
            } else {
              final selector = name.split(RegExp(r'\s+')).last;
              selectors.add(selector);
            }
            scan(rest.substring(open + 1, close));
            j = close + 1;
          }
          found.add(_Icu(arg, kind, selectors));
        } else {
          scan(inner);
        }
      } else {
        scan(inner);
      }
      i = end + 1;
    }
  }

  scan(message);
  return found;
}

int _closing(String text, int open) {
  var depth = 0;
  for (var i = open; i < text.length; i++) {
    if (text[i] == '{') depth++;
    if (text[i] == '}' && --depth == 0) return i;
  }
  return -1;
}

int _topLevelComma(String text, int from) {
  var depth = 0;
  for (var i = from; i < text.length; i++) {
    if (text[i] == '{') depth++;
    if (text[i] == '}') depth--;
    if (text[i] == ',' && depth == 0) return i;
  }
  return -1;
}

const _pluralCategories = {'zero', 'one', 'two', 'few', 'many'};

/// Problems with the plural or select structure of [value] against
/// [english]: the same arguments and kinds, `other` present, every exact
/// match (`=0`) and every `select` option kept. A plural may add the
/// categories its language needs.
List<String> _icuProblems(String english, String value) {
  final want = {for (final p in _icuParts(english)) p.id: p};
  final have = {for (final p in _icuParts(value)) p.id: p};
  final problems = <String>[];
  for (final id in want.keys.where((id) => !have.containsKey(id))) {
    problems.add('must keep the {${id.replaceFirst(',', ', ')}, ...} choice');
  }
  for (final id in have.keys.where((id) => !want.containsKey(id))) {
    problems.add(
      'has a {${id.replaceFirst(',', ', ')}, ...} choice that '
      'English does not',
    );
  }
  for (final entry in want.entries) {
    final got = have[entry.key];
    if (got == null) continue;
    final name = entry.key.replaceFirst(',', ', ');
    final expected = entry.value.selectors;
    final isPlural = entry.value.kind != 'select';
    if (!got.selectors.contains('other')) {
      problems.add('{$name, ...} needs an "other" option');
    }
    for (final selector in expected) {
      final required =
          !isPlural || selector == 'other' || selector.startsWith('=');
      if (required && !got.selectors.contains(selector)) {
        problems.add('{$name, ...} must keep the "$selector" option');
      }
    }
    for (final selector in got.selectors.difference(expected)) {
      final allowed =
          isPlural &&
          (_pluralCategories.contains(selector) || selector.startsWith('='));
      if (!allowed) {
        problems.add(
          '{$name, ...} has an option "$selector" that English '
          'does not',
        );
      }
    }
  }
  return problems;
}

bool _balanced(String message) {
  var depth = 0;
  for (final unit in message.runes) {
    if (unit == 0x7B) depth++;
    if (unit == 0x7D) depth--;
    if (depth < 0) return false;
  }
  return depth == 0;
}

/// Checks a translation against the English [source].
///
/// Errors: a message the source does not have, a placeholder that differs, a
/// plural or select that differs, unbalanced braces, a value that is not text,
/// a missing or wrong `@@locale`. Warnings: a message that is missing (it
/// falls back to English) or identical to the English text.
List<ArbProblem> checkTranslation({
  required Map<String, Object?> source,
  required Map<String, Object?> translation,
  required String locale,
}) {
  final problems = <ArbProblem>[];
  final declared = translation['@@locale'];
  if (declared == null) {
    problems.add(const ArbProblem('"@@locale" is missing'));
  } else if (declared.toString().replaceAll('-', '_') !=
      locale.replaceAll('-', '_')) {
    problems.add(
      ArbProblem('"@@locale" is "$declared" but the file is for "$locale"'),
    );
  }
  for (final key in translation.keys.where(isMessageKey)) {
    final english = source[key];
    final value = translation[key];
    if (english is! String) {
      problems.add(ArbProblem('"$key" is not a message of the app'));
      continue;
    }
    if (value is! String) {
      problems.add(ArbProblem('"$key" must be text'));
      continue;
    }
    if (!_balanced(value)) {
      problems.add(ArbProblem('"$key" has unbalanced braces'));
    }
    if (!_setEquals(_placeholders(english), _placeholders(value))) {
      problems.add(
        ArbProblem(
          '"$key" must use the placeholders '
          '${_placeholders(english).map((p) => '{$p}').join(', ')} exactly',
        ),
      );
    }
    for (final problem in _icuProblems(english, value)) {
      problems.add(ArbProblem('"$key" $problem'));
    }
    if (value.trim().isEmpty) {
      problems.add(ArbProblem('"$key" is empty', isError: false));
    } else if (value == english) {
      problems.add(ArbProblem('"$key" is the same as English', isError: false));
    }
  }
  for (final key in source.keys.where(isMessageKey)) {
    if (!translation.containsKey(key)) {
      problems.add(
        ArbProblem('"$key" is missing (English is shown)', isError: false),
      );
    }
  }
  return problems;
}

bool _setEquals(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

/// A file for a translator to fill in: every message of the English [source]
/// with its description and placeholders, holding the [existing] translation
/// where there is one and the English text otherwise.
String buildTemplate({
  required Map<String, Object?> source,
  required Map<String, Object?>? existing,
  required String locale,
}) {
  final out = <String, Object?>{'@@locale': locale.replaceAll('-', '_')};
  for (final key in source.keys.where(isMessageKey)) {
    out[key] = existing?[key] ?? source[key];
    final meta = source['@$key'];
    if (meta != null) out['@$key'] = meta;
  }
  return '${const JsonEncoder.withIndent('  ').convert(out)}\n';
}
