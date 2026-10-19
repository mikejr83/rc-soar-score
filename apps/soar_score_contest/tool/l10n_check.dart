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

/// One `{arg, kind, selector{...} ...}` of a message.
class _Icu {
  _Icu(this.arg, this.kind, this.selectors);

  final String arg;
  final String kind;
  final Set<String> selectors;

  String get id => '$arg,$kind';
}

/// What a message uses: its arguments, its plural and select choices and
/// the places where the braces are not valid message syntax.
class _Parsed {
  final args = <String>{};
  final choices = <_Icu>[];
  final syntax = <String>[];
}

final _name = RegExp(r'^[A-Za-z_]\w*$');
final _selector = RegExp(r'^(=\d+|\w+)$');
const _choiceKinds = {'plural', 'select', 'selectordinal'};

_Parsed _parse(String message) {
  final parsed = _Parsed();
  _scan(message, parsed);
  return parsed;
}

/// Walks [text], telling branch text apart from argument expressions.
/// `'{'` quotes a brace the way ICU does.
void _scan(String text, _Parsed out) {
  var i = 0;
  while (i < text.length) {
    final c = text[i];
    if (c == "'" && i + 1 < text.length) {
      if (text[i + 1] == "'") {
        i += 2;
        continue;
      }
      if (text[i + 1] == '{' || text[i + 1] == '}') {
        final close = text.indexOf("'", i + 2);
        i = close < 0 ? text.length : close + 1;
        continue;
      }
    }
    if (c == '}') {
      out.syntax.add('has a "}" with no "{"');
      i++;
      continue;
    }
    if (c != '{') {
      i++;
      continue;
    }
    final end = _closing(text, i);
    if (end < 0) {
      out.syntax.add('has a "{" that is never closed');
      return;
    }
    _expression(text.substring(i + 1, end), out);
    i = end + 1;
  }
}

/// The inside of one `{...}`: `name`, `name, type[, style]` or a choice.
void _expression(String inner, _Parsed out) {
  final first = _topLevelComma(inner, 0);
  final name = (first < 0 ? inner : inner.substring(0, first)).trim();
  if (!_name.hasMatch(name)) {
    out.syntax.add('has the malformed expression {$inner}');
    return;
  }
  out.args.add(name);
  if (first < 0) return;
  final second = _topLevelComma(inner, first + 1);
  final kind = inner
      .substring(first + 1, second < 0 ? inner.length : second)
      .trim();
  if (!_choiceKinds.contains(kind)) {
    if (kind.isEmpty || inner.contains('{')) {
      out.syntax.add('has the malformed expression {$inner}');
    }
    return;
  }
  if (second < 0) {
    out.syntax.add('has the {$name, $kind} choice with no options');
    return;
  }
  final selectors = <String>{};
  final rest = inner.substring(second + 1);
  var j = 0;
  while (j < rest.length) {
    if (rest.substring(j).trim().isEmpty) break;
    final open = rest.indexOf('{', j);
    final close = open < 0 ? -1 : _closing(rest, open);
    if (close < 0) {
      out.syntax.add('has the {$name, $kind} choice with an unreadable option');
      break;
    }
    final words = rest.substring(j, open).trim().split(RegExp(r'\s+'));
    if (words.first.startsWith('offset:') && words.length > 1) {
      words.removeAt(0);
    }
    final selector = words.join(' ');
    if (!_selector.hasMatch(selector)) {
      out.syntax.add('has the option "$selector" in {$name, $kind}');
    }
    selectors.add(selector);
    _scan(rest.substring(open + 1, close), out);
    j = close + 1;
  }
  out.choices.add(_Icu(name, kind, selectors));
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

bool _balanced(String message) {
  var depth = 0;
  for (final unit in message.runes) {
    if (unit == 0x7B) depth++;
    if (unit == 0x7D) depth--;
    if (depth < 0) return false;
  }
  return depth == 0;
}

const _pluralCategories = {'zero', 'one', 'two', 'few', 'many'};

/// Problems with the plural or select structure of [value] against
/// [english]: the same arguments and kinds, `other` present, every exact
/// match (`=0`) and every `select` option kept. A plural may add the
/// categories its language needs.
List<String> _icuProblems(_Parsed english, _Parsed value) {
  final want = {for (final p in english.choices) p.id: p};
  final have = {for (final p in value.choices) p.id: p};
  final problems = <String>[];
  for (final id in want.keys.where((id) => !have.containsKey(id))) {
    problems.add('must keep the {${id.replaceFirst(',', ', ')}, ...} choice');
  }
  for (final id in have.keys.where((id) => !want.containsKey(id))) {
    problems.add(
      'has a {${id.replaceFirst(',', ', ')}, ...} choice that English does not',
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
          '{$name, ...} has an option "$selector" that English does not',
        );
      }
    }
  }
  return problems;
}

/// The locale a file is checked against: [explicit] (`--locale`), else the
/// one in a recognized `app_<locale>.arb` file name, else what the file
/// declares in `@@locale`, else `en`.
String expectedLocale({
  String? explicit,
  required String path,
  Object? declared,
}) {
  if (explicit != null) return explicit;
  final name = path.split(RegExp(r'[\\/]')).last;
  final fromName = RegExp(r'^app_(.+)\.arb$').firstMatch(name)?.group(1);
  return fromName ?? declared?.toString() ?? 'en';
}

/// Checks a translation against the English [source].
///
/// Errors: a message the source does not have, a placeholder that differs, a
/// plural or select that differs, unbalanced braces, a value that is not text,
/// an empty value, a missing or wrong `@@locale`. Warnings: a message that is
/// missing (it falls back to English) or identical to the English text.
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
    final want = _parse(english);
    final got = _parse(value);
    if (!_balanced(value)) {
      problems.add(ArbProblem('"$key" has unbalanced braces'));
    } else {
      for (final problem in got.syntax) {
        problems.add(ArbProblem('"$key" $problem'));
      }
    }
    if (!_setEquals(want.args, got.args)) {
      problems.add(
        ArbProblem(
          '"$key" must use the placeholders '
          '${want.args.map((p) => '{$p}').join(', ')} exactly',
        ),
      );
    }
    for (final problem in _icuProblems(want, got)) {
      problems.add(ArbProblem('"$key" $problem'));
    }
    if (value.trim().isEmpty) {
      problems.add(
        ArbProblem(
          '"$key" is empty; leave the key out or keep the English text',
        ),
      );
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
