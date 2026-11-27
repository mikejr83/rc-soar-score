import 'dart:io';

import 'package:soar_score_server/mail/email_template.dart';
import 'package:test/test.dart';

void main() {
  const allowed = {'a', 'b'};

  test('fills each placeholder in one pass', () {
    final t = EmailTemplate('x {{a}} y {{b}}', allowed: allowed);
    // A value holding a placeholder is not expanded again.
    expect(t.fill({'a': '{{b}}', 'b': '2'}), 'x {{b}} y 2');
  });

  test('an empty value drops the space before it', () {
    final t = EmailTemplate('Hello {{a}},{{b}}!', allowed: allowed);
    expect(t.fill({'a': '', 'b': ''}), 'Hello,!');
    expect(t.fill({'a': 'Al', 'b': ' (X)'}), 'Hello Al, (X)!');
  });

  test('escape applies to values and not to the template', () {
    final t = EmailTemplate('<b>{{a}}</b>', allowed: allowed);
    expect(
      t.fill({'a': 'A & <B> "c"', 'b': ''}, escape: escapeHtml),
      '<b>A &amp; &lt;B&gt; &quot;c&quot;</b>',
    );
  });

  test('rejects a placeholder it does not know', () {
    expect(
      () => EmailTemplate('{{nope}}', allowed: allowed),
      throwsFormatException,
    );
  });

  group('InvitationTemplates', () {
    test('loads the shipped files and accepts every placeholder', () async {
      final templates = await InvitationTemplates.load(Directory('email'));
      expect(templates.html.source, contains('{{link}}'));
      expect(templates.text.source, contains('{{link}}'));
    });

    test('a missing directory fails', () {
      expect(
        InvitationTemplates.load(Directory('no-such-email-dir')),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
