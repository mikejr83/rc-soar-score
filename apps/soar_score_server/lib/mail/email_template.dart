import 'dart:io';

/// A message template with `{{name}}` placeholders, read from a file.
///
/// The files are the designer's, untouched: no escaping or code lives in them.
/// [fill] puts the values in.
class EmailTemplate {
  EmailTemplate(this.source, {required Set<String> allowed}) {
    for (final match in _placeholder.allMatches(source)) {
      final name = match.group(2)!;
      if (!allowed.contains(name)) {
        throw FormatException('Unknown placeholder {{$name}} in template.');
      }
    }
  }

  final String source;

  static final _placeholder = RegExp(r'( ?)\{\{(\w+)\}\}');

  /// The template with each placeholder replaced by its value in [values].
  ///
  /// One pass over the template, so a value that itself contains `{{x}}` is
  /// never expanded. A placeholder with an empty value also drops the single
  /// space before it, so `Hello {{pilotName}},` reads `Hello,` with no name.
  /// [escape] is applied to every value (HTML escaping for the HTML part,
  /// nothing for the plain-text part).
  String fill(Map<String, String> values, {String Function(String)? escape}) =>
      source.replaceAllMapped(_placeholder, (match) {
        final value = values[match.group(2)!];
        if (value == null) {
          throw StateError('No value for {{${match.group(2)}}}.');
        }
        if (value.isEmpty) return '';
        return '${match.group(1)}${escape == null ? value : escape(value)}';
      });
}

/// Escapes [text] for HTML text and double-quoted attribute values.
String escapeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

/// The two parts of the invitation email, read from the server's `email/`
/// directory.
class InvitationTemplates {
  InvitationTemplates({required this.html, required this.text});

  /// The placeholders the invitation templates may use.
  static const placeholders = {
    'contestName',
    'pilotName',
    'locationLine',
    'dateLine',
    'link',
    'logoUrl',
  };

  static const htmlFile = 'invitation-email.html';
  static const textFile = 'invitation-email.txt';

  final EmailTemplate html;
  final EmailTemplate text;

  /// Reads both templates from [directory]. Throws when a file is missing or
  /// uses a placeholder the mailer does not fill, so a bad deployment stops at
  /// startup and not at the first send.
  static Future<InvitationTemplates> load(Directory directory) async {
    Future<EmailTemplate> read(String name) async {
      final file = File('${directory.path}${Platform.pathSeparator}$name');
      if (!await file.exists()) {
        throw FileSystemException('Email template not found', file.path);
      }
      return EmailTemplate(await file.readAsString(), allowed: placeholders);
    }

    return InvitationTemplates(
      html: await read(htmlFile),
      text: await read(textFile),
    );
  }

  /// Where the templates sit next to the program: `email/` beside `lib/` when
  /// run from source, and beside `bin/` in the container image.
  static Directory defaultDirectory() {
    final script = File(Platform.script.toFilePath());
    return Directory(
      '${script.parent.parent.path}${Platform.pathSeparator}email',
    );
  }
}
