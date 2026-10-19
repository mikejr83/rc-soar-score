import 'dart:io';

import 'l10n_check.dart';

/// Helps people translate the contest app (see docs/translating.md).
///
///     dart run tool/l10n.dart template fr-FR [--out app_fr.arb]
///     dart run tool/l10n.dart validate app_fr.arb
///
/// Run from `apps/soar_score_contest`. `template` writes the English
/// messages, with their descriptions, ready to translate (keeping any existing
/// translation). `validate` checks a returned file and exits 1 on errors.
const _sourcePath = 'lib/l10n/app_en.arb';

void main(List<String> args) {
  if (args.length < 2 || !const {'template', 'validate'}.contains(args[0])) {
    stderr.writeln(
      'usage: dart run tool/l10n.dart template <locale> [--out <file>]\n'
      '       dart run tool/l10n.dart validate <file> [--locale <locale>]',
    );
    exit(64);
  }
  final source = parseArb(File(_sourcePath).readAsStringSync());
  if (args[0] == 'template') {
    final locale = args[1];
    final existing = File(_arbPath(locale));
    final text = buildTemplate(
      source: source,
      existing: existing.existsSync()
          ? parseArb(existing.readAsStringSync())
          : null,
      locale: locale,
    );
    final out = _option(args, '--out');
    if (out == null) {
      stdout.write(text);
    } else {
      File(out).writeAsStringSync(text);
      stdout.writeln('Wrote $out');
    }
    return;
  }
  final file = File(args[1]);
  final Map<String, Object?> translation;
  try {
    translation = parseArb(file.readAsStringSync());
  } on FormatException catch (e) {
    stderr.writeln('error: ${file.path} is not valid JSON: ${e.message}');
    exit(1);
  }
  final locale =
      _option(args, '--locale') ??
      translation['@@locale']?.toString() ??
      _localeFromName(file.path);
  final problems = checkTranslation(
    source: source,
    translation: translation,
    locale: locale,
  );
  problems.forEach(stdout.writeln);
  final errors = problems.where((p) => p.isError).length;
  final total = source.keys.where(isMessageKey).length;
  final done = translation.keys
      .where(isMessageKey)
      .where((key) => translation[key] != source[key])
      .length;
  stdout.writeln(
    '$done of $total messages translated; $errors errors, '
    '${problems.length - errors} warnings.',
  );
  exit(errors == 0 ? 0 : 1);
}

String _arbPath(String locale) =>
    'lib/l10n/app_${locale.replaceAll('-', '_')}.arb';

String _localeFromName(String path) {
  final name = path.split(RegExp(r'[\\/]')).last;
  final match = RegExp(r'^app_(.+)\.arb$').firstMatch(name);
  return match?.group(1) ?? 'en';
}

String? _option(List<String> args, String name) {
  final at = args.indexOf(name);
  return at >= 0 && at + 1 < args.length ? args[at + 1] : null;
}
