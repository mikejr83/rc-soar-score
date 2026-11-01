import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/bundled_licences.dart';

void main() {
  test('only bundled entries become licence entries', () {
    final json = jsonEncode({
      'schema': 1,
      'texts': ['MIT text', 'Other text'],
      'products': [
        {
          'entries': [
            {
              'name': 'a-package',
              'source': 'dart',
              'texts': [1],
            },
            {
              'name': 'cpp-httplib',
              'source': 'bundled',
              'license': 'MIT',
              'note': 'Windows only.',
              'texts': [0],
            },
          ],
        },
      ],
    });

    final entries = bundledLicenceEntries(json).toList();

    expect(entries, hasLength(1));
    expect(entries.single.packages, ['cpp-httplib']);
    final text = entries.single.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('Licence: MIT'));
    expect(text, contains('Windows only.'));
    expect(text, contains('MIT text'));
  });

  test('the committed asset parses and lists the Windows helpers', () {
    final json = File(bundledLicencesAsset).readAsStringSync();

    final names = bundledLicenceEntries(json).expand((e) => e.packages).toSet();

    expect(names, containsAll(['cpp-httplib', 'nlohmann/json']));
    expect(names.any((n) => n.contains('mdbtools')), isTrue);
  });
}
