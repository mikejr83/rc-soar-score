import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/exchange/support_bundle.dart';
import 'package:soar_score_data/soar_score_data.dart';

void main() {
  test('a bundle holds the manifest, the contest and the log', () {
    final bytes = encodeSupportBundle(
      manifest: {'format': 'rcsoar-support'},
      contest: utf8.encode('{"a":1}'),
      log: 'line\n',
    );

    expect(isSupportBundle(bytes), isTrue);
    final archive = ZipDecoder().decodeBytes(bytes);
    expect(archive.files.map((f) => f.name), [
      'manifest.json',
      'contest.json',
      'app.log',
    ]);
    expect(utf8.decode(contestFileOf(bytes)), '{"a":1}');
  });

  test('a plain file is its own contest file', () {
    final plain = utf8.encode('{"format":"x"}');
    expect(isSupportBundle(plain), isFalse);
    expect(contestFileOf(plain), same(plain));
  });

  test('a zip without a contest file is refused', () {
    final zip = ZipEncoder().encode(
      Archive()..addFile(ArchiveFile.bytes('app.log', utf8.encode('x'))),
    );

    expect(
      () => contestFileOf(zip),
      throwsA(
        isA<ExchangeException>().having(
          (e) => e.code,
          'code',
          'not_a_contest_file',
        ),
      ),
    );
  });

  test('a damaged zip is refused', () {
    expect(
      () => contestFileOf([0x50, 0x4b, 0x03, 0x04, 1, 2, 3, 4, 5]),
      throwsA(isA<ExchangeException>()),
    );
  });
}
