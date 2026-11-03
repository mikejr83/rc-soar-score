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

  group('GliderScore competition fixtures', () {
    const compFiles = [
      'comps_reference.json',
      'comps_edge_cases.json',
      'comps_missing_columns.json',
    ];

    Map<String, List<Map<String, Object?>>> tables(String name) {
      final list = _load(name)['tables']! as List<Object?>;
      return {
        for (final t in list.cast<Map<String, Object?>>())
          t['name']! as String: [
            for (final row in (t['rows']! as List<Object?>))
              (row as Map).cast<String, Object?>(),
          ],
      };
    }

    for (final file in compFiles) {
      test('$file is a gs-import/v1 snapshot with consistent counts', () {
        final snapshot = _load(file);
        expect(snapshot['schema'], GliderScoreImportResult.schema);
        for (final t
            in (snapshot['tables']! as List<Object?>)
                .cast<Map<String, Object?>>()) {
          expect(t['rowCount'], (t['rows']! as List<Object?>).length);
          expect(t['rowCapExceeded'], isFalse);
        }
      });

      test('$file refers only to pilots it carries', () {
        final t = tables(file);
        final pilots = {for (final p in t['Pilots']!) p['PilotNo']};
        for (final row in t['CompPilots']!) {
          expect(pilots, contains(row['PilotNo']), reason: '$row');
        }
      });

      test('$file holds no real name, venue or email', () {
        final t = tables(file);
        for (final c in t['Comps']!) {
          expect(c['CompName'], matches(RegExp(r'^Fixture Open \d+$')));
          if (c['CompVenue'] != null) {
            expect(c['CompVenue'], 'Example Field');
          }
        }
        for (final row in t['CompPilots']!) {
          final model = row['Model'];
          if (model != null) {
            expect(
              (model as String).toLowerCase().trim(),
              matches(RegExp(r'^(example model \d+|\w+ glider)$')),
            );
          }
        }
        for (final p in t['Pilots']!) {
          final email = p['Email'];
          if (email is String && email.trim().isNotEmpty) {
            expect(email, endsWith('@example.test'));
          }
        }
      });
    }

    test('the reference snapshot has the F5J, F3J and F5L competitions', () {
      final t = tables('comps_reference.json');
      final classes = {
        for (final c in t['Comps']!) c['CompNo']: c['GSCompClass'],
      };
      expect(classes, {20: 'F3J', 21: 'F5J', 22: 'F5J', 39: 'F5J', 40: 'F5L'});
      expect(
        t['Dur']!.map((r) => r['CompNo']).toSet(),
        classes.keys.toSet(),
        reason: 'every competition has its config row',
      );
      expect(
        t['CompPilots']!.where((r) => r['CompNo'] == 21 && r['Retired'] == 1),
        hasLength(4),
      );
    });

    test('the edge-case snapshot covers teams, roles, drops and gaps', () {
      final t = tables('comps_edge_cases.json');
      final comps = {for (final c in t['Comps']!) c['CompNo']: c};
      expect(comps[9001]!['UseTeams'], 1);
      expect([
        for (var i = 1; i <= 5; i++) comps[9001]!['Drop${i}AtRound'],
      ], everyElement(lessThan(99)));
      final roles = {
        for (final r in t['CompPilots']!)
          if (r['CompNo'] == 9002) r['Role'],
      };
      expect(roles, {'Plt', 'TM/Plt', 'CD/Plt', 'CD', 'Hlp', 'TM'});
      expect(
        t['CompPilots']!.where((r) => r['CompNo'] == 9002 && r['Retired'] == 1),
        hasLength(2),
      );
      expect(t['Dur']!.map((r) => r['CompNo']), isNot(contains(9003)));
      expect(comps[9004]!['GSCompClass'], 'F3Z');
    });

    test('the missing-columns snapshot keeps only the required columns', () {
      final t = tables('comps_missing_columns.json');
      expect(t.keys, isNot(contains('Roles')));
      expect(t.keys, isNot(contains('DBParams')));
      expect(t['Comps']!.single.keys.toSet(), {
        'CompNo',
        'CompName',
        'GSCompClass',
        'CompDate',
      });
      for (final row in t['CompPilots']!) {
        expect(row.keys.toSet(), {'CompNo', 'PilotNo'});
      }
      expect(t['Dur']!.single.keys.toSet(), {'CompNo', 'durTargetTime'});
    });
  });
}
