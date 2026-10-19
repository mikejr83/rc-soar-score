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
final _icuKind = RegExp(r'\{\w+,\s*(plural|select|selectordinal)\b');

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

Set<String> _icuKinds(String message) => {
  for (final match in _icuKind.allMatches(message)) match.group(1)!,
};

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
    if (!_setEquals(_icuKinds(english), _icuKinds(value))) {
      problems.add(
        ArbProblem('"$key" must keep the same plural or select structure'),
      );
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
