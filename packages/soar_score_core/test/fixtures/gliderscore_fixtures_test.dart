import 'dart:convert';
import 'dart:io';

import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

Map<String, Object?> _load(String name) =>
    jsonDecode(File('test/fixtures/gliderscore/$name').readAsStringSync())
        as Map<String, Object?>;

List<Map<String, Object?>> _pilotRows(String name) {
  final tables = _load(name)['tables']! as List<Object?>;
  final pilots = tables.cast<Map<String, Object?>>().single;
  expect(pilots['name'], 'Pilots');
  final rows = (pilots['rows']! as List<Object?>).cast<Map<String, Object?>>();
  expect(pilots['rowCount'], rows.length);
  return rows;
}

void main() {
  const files = [
    'pilots_reference.json',
    'pilots_edge_cases.json',
    'pilots_old_columns.json',
    'pilots_extra_columns.json',
  ];

  group('GliderScore pilot fixtures', () {
    for (final file in files) {
      test('$file is a gs-import/v1 snapshot', () {
        final snapshot = _load(file);
        expect(snapshot['schema'], GliderScoreImportResult.schema);
        expect(_pilotRows(file), isNotEmpty);
      });

      test('$file holds no real email address', () {
        for (final row in _pilotRows(file)) {
          final email = row['Email'];
          if (email is String && email.trim().isNotEmpty) {
            expect(email.trim().toLowerCase(), endsWith('@example.test'));
          }
        }
      });
    }

    test('the reference snapshot has the shape of the real file', () {
      final rows = _pilotRows('pilots_reference.json');
      bool isTest(Map<String, Object?> r) =>
          (r['LastName']! as String).startsWith('ZZ');
      expect(rows, hasLength(158));
      expect(rows.where(isTest), hasLength(74));
      expect(rows.where((r) => r.containsKey('Email')), hasLength(21));
      expect(
        rows.map((r) => r['PilotNo']).toSet(),
        hasLength(rows.length),
        reason: 'pilot numbers are unique',
      );
    });

    test(
      'derived snapshots carry only allowlisted columns and fake values',
      () {
        const allowed = {
          'PilotNo', 'Country', 'State', 'UsualClass', 'Filter', 'FirstName',
          'LastName', 'Email', 'FAINumber', 'FAI_ID', 'OtherRegistration',
          'Club', 'Town',
          // Added on purpose to the extra-columns snapshot.
          'FutureColumn', 'AnotherNewThing',
        };
        final number = RegExp(r'^(0|(FAI|REG)-\d+)$');
        for (final file in [
          'pilots_reference.json',
          'pilots_old_columns.json',
          'pilots_extra_columns.json',
        ]) {
          for (final row in _pilotRows(file)) {
            expect(allowed.containsAll(row.keys), isTrue, reason: '$file $row');
            for (final key in ['FAINumber', 'FAI_ID', 'OtherRegistration']) {
              final value = row[key];
              if (value != null) {
                expect(number.hasMatch(value as String), isTrue, reason: key);
              }
            }
          }
        }
      },
    );

    test('the old-column snapshot lacks the newer columns', () {
      for (final row in _pilotRows('pilots_old_columns.json')) {
        expect(row.keys, isNot(contains('Email')));
        expect(row.keys, isNot(contains('FAI_ID')));
        expect(row.keys, isNot(contains('OtherRegistration')));
      }
    });
  });
}
