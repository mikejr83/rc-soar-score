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
      'comps_integrity_cases.json',
      'comps_missing_columns.json',
      'draws_reference.json',
      'draws_edge_cases.json',
    ];

    // Every column a competition snapshot may carry, with the pattern every
    // string value of that column must match. A column or string that is not
    // listed fails, so a new value cannot reach a fixture unnoticed.
    final patterns = <String, RegExp>{
      'Comps.CompID': RegExp(r'^FIXTURE\d+$'),
      'Comps.CompName': RegExp(r'^Fixture Open \d+$'),
      'Comps.CompVenue': RegExp(r'^Example Field$'),
      'Comps.CompDate': RegExp(r'^\d\d/\d\d/\d\d \d\d:\d\d:\d\d$'),
      'Comps.GSCompClass': RegExp(r'^[A-Za-z0-9]+$'),
      'Comps.F3QDrop6to10': RegExp(r'^[0-9,]*$'),
      'CompPilots.PilotClass': RegExp(r'^[A-Za-z0-9]{1,4}$'),
      'CompPilots.Role': RegExp(r'^(Plt|TM|TM/Plt|CD/Plt|Hlp|CD)$'),
      'CompPilots.Model': RegExp(
        r'^(Example Model \d+|Alpha Glider|Beta Glider|beta glider |Gamma Glider)$',
      ),
      'CompPilots.ModelData': RegExp(r'^-?\d+$'),
      'Pilots.FirstName': RegExp(r'^[A-Za-z]+$'),
      'Pilots.LastName': RegExp(r'^(ZZ)?[A-Za-z]+\d*$'),
      'Pilots.Email': RegExp(r'^fixture\d+@example\.test$'),
      'Pilots.Country': RegExp(r'^[A-Za-z]{0,3}$'),
      'Pilots.State': RegExp(r'^[A-Za-z ]{0,3}$'),
      'Pilots.UsualClass': RegExp(r'^[A-Za-z0-9]{0,8}$'),
      'Pilots.Filter': RegExp(r'^[A-Za-z0-9]{0,3}$'),
      'Pilots.FAINumber': RegExp(r'^(0|FAI-\d+)$'),
      'Pilots.FAI_ID': RegExp(r'^(0|FAI-\d+)$'),
      'Pilots.OtherRegistration': RegExp(r'^(0|REG-\d+)$'),
      'Pilots.Club': RegExp(r'^Example Club \d$'),
      'Pilots.Town': RegExp(r'^Exampleton$'),
      'Roles.Role': RegExp(r'^(Plt|TM|TM/Plt|CD/Plt|Hlp|CD)$'),
      'Roles.RoleName': RegExp(
        r'^(Pilot|Team Manager|Team Manager/Pilot|Comp Director/Pilot|Helper|Competition Director)$',
      ),
      'Dur.durPilotsMin': RegExp(
        r'^(([A-Za-z0-9]+=[A-Za-z0-9.]*&?)*|[0-9,]*)$',
      ),
      'DBParams.Property': RegExp(r'^DBVersion$'),
      'DBParams.PRValue': RegExp(r'^\d+\.\d+$'),
      'Scores.Updated': RegExp(r'^(True|False)$'),
    };
    // Columns that hold numbers and flags only, per table.
    const numericKeys = <String, Set<String>>{
      'Comps': {
        'CompNo', 'Drop1AtRound', 'Drop2AtRound', 'Drop3AtRound',
        'Drop4AtRound', 'Drop5AtRound', 'UseTeams', 'UseTeamProtection',
        'UseClasses', 'UseModels', 'UsePilotNumbering', 'Enforce20KHz',
        'GroupScoreDecimals', 'ScoresLocked', 'NbrForTeamScore',
        'printCountry', 'RoundOrTruncate', 'GroupScoreOption',
        'printRegistration', 'UseRoles', 'DropScoreOption', 'AssignHelpers',
        'DrawMode', 'PrelimCompNo', 'IsPublic', 'UseRegistration',
        'UseRegistrationIdx', //
      },
      'CompPilots': {
        'CompNo', 'PilotNo', 'Team', 'DrawFreq', 'Retired', 'StartNo',
        'IsPilot', 'OmitFromTeamScore', //
      },
      'Pilots': {'PilotNo'},
      'Scores': {
        'CompNo', 'TaskNo', 'RoundNo', 'GroupNo', 'ReFlightNo', 'PilotNo',
        'SeqNo', 'DrawFreq', 'Time1Mins', 'Time1Secs', 'Time2Mins',
        'Time2Secs', 'FlightScoreDeduction', 'Landing', 'RawScore',
        'NormalisedScore', 'Penalty', 'OriginalRoundNo', 'ScoresChecked',
        'LandingOver75m', 'Helper', 'Laps', 'F5JMotorReStarted', //
      },
      'Roles': {},
      'DBParams': {},
      'Dur': {
        'CompNo', 'durTargetTime', 'durDecimalsForTiming', 'durLndg',
        'durNumberOfTimekeepers', 'durGroupsPerRound', 'durPilotsMax',
        'durDrawLocked', 'durFlightPenalty', 'durNbrOfLanes', 'durRefHeight',
        'durPenaltyUpToRefHeight', 'durPenaltyOverRefHeight',
        'durAllowBackToBack', 'DurPointsPerSecond', 'F5JMotorRestartOption',
        //
      },
    };

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

      test('$file carries only known tables, columns and fake values', () {
        final t = tables(file);
        for (final entry in t.entries) {
          expect(
            numericKeys.keys,
            contains(entry.key),
            reason: 'unknown table ${entry.key} in $file',
          );
          final numeric = numericKeys[entry.key]!;
          for (final row in entry.value) {
            for (final cell in row.entries) {
              final key = '${entry.key}.${cell.key}';
              final value = cell.value;
              if (value is String) {
                final pattern = patterns[key];
                expect(pattern, isNotNull, reason: 'unlisted text column $key');
                expect(
                  pattern!.hasMatch(value),
                  isTrue,
                  reason: '$file $key = "$value"',
                );
              } else {
                expect(
                  value == null || value is num,
                  isTrue,
                  reason: '$file $key is not text or a number',
                );
                expect(
                  numeric.contains(cell.key),
                  isTrue,
                  reason: 'unlisted numeric column $key in $file',
                );
              }
            }
          }
        }
      });

      test('$file uses only the fixed model names', () {
        final models = {
          for (final r in tables(file)['CompPilots']!)
            if (r['Model'] != null) r['Model'] as String,
        };
        const hand = {
          'Alpha Glider',
          'Beta Glider',
          'beta glider ',
          'Gamma Glider',
        };
        for (final m in models) {
          final generated = RegExp(r'^Example Model \d+$').hasMatch(m);
          expect(generated || hand.contains(m), isTrue, reason: m);
        }
      });
    }

    test('the lookup tables are the fixed six roles and one DBVersion', () {
      for (final file in ['comps_reference.json', 'comps_edge_cases.json']) {
        final t = tables(file);
        expect(t['Roles'], const [
          {'Role': 'TM', 'RoleName': 'Team Manager'},
          {'Role': 'Plt', 'RoleName': 'Pilot'},
          {'Role': 'TM/Plt', 'RoleName': 'Team Manager/Pilot'},
          {'Role': 'CD/Plt', 'RoleName': 'Comp Director/Pilot'},
          {'Role': 'Hlp', 'RoleName': 'Helper'},
          {'Role': 'CD', 'RoleName': 'Competition Director'},
        ]);
        expect(t['DBParams'], [
          {'Property': 'DBVersion', 'PRValue': '6.78'},
        ]);
      }
    });

    for (final file in [
      'comps_reference.json',
      'comps_edge_cases.json',
      'comps_missing_columns.json',
      'draws_reference.json',
      'draws_edge_cases.json',
    ]) {
      test('$file refers only to pilots it carries', () {
        final t = tables(file);
        final pilots = {for (final p in t['Pilots']!) p['PilotNo']};
        for (final row in t['CompPilots']!) {
          expect(pilots, contains(row['PilotNo']), reason: '$row');
        }
      });
    }

    group('draw fixtures (Scores)', () {
      // The (round, group) cells of one competition's first flights.
      Map<String, List<Map<String, Object?>>> cells(
        List<Map<String, Object?>> scores,
        int comp, {
        bool reflights = false,
      }) {
        final out = <String, List<Map<String, Object?>>>{};
        for (final r in scores) {
          if (r['CompNo'] != comp || (r['ReFlightNo'] != 0) != reflights) {
            continue;
          }
          (out['${r['RoundNo']}/${r['GroupNo']}'] ??= []).add(r);
        }
        return out;
      }

      late Map<String, List<Map<String, Object?>>> t;
      setUpAll(() => t = tables('draws_reference.json'));

      test(
        'every Scores row belongs to a competition and pilot it carries',
        () {
          final members = {
            for (final r in t['CompPilots']!) '${r['CompNo']}/${r['PilotNo']}',
          };
          expect(t['Scores']!.length, greaterThan(500));
          for (final r in t['Scores']!) {
            expect(
              members,
              contains('${r['CompNo']}/${r['PilotNo']}'),
              reason: '$r',
            );
          }
        },
      );

      test('the reference holds the five scenarios of the draw plan', () {
        final scores = t['Scores']!;
        expect(
          {for (final c in t['Comps']!) c['CompNo']},
          {
            15, 21, 26, 28, 39, //
          },
        );
        Map<int, Object?> dur = {
          for (final d in t['Dur']!) d['CompNo']! as int: d,
        };

        // 15: lane count 6 and a group of 7 pilots (one lane too many).
        expect(dur[15]!, containsPair('durNbrOfLanes', 6));
        expect(cells(scores, 15).values.map((c) => c.length), contains(7));
        // 21: lane count 0, gaps in SeqNo, unequal groups, re-flights and
        // retired pilots (scored, unscored and re-flight rows for phase D).
        expect(dur[21]!, containsPair('durNbrOfLanes', 0));
        expect(
          cells(scores, 21).values.where((c) {
            final seq = [for (final r in c) r['SeqNo']! as int]..sort();
            return seq.first != 1 || seq.last != seq.length;
          }),
          isNotEmpty,
        );
        expect(cells(scores, 21, reflights: true), isNotEmpty);
        expect(
          t['CompPilots']!.where((r) => r['CompNo'] == 21 && r['Retired'] == 1),
          isNotEmpty,
        );
        // 26: configured groups per round (1) differ from the groups drawn.
        expect(dur[26]!, containsPair('durGroupsPerRound', 1));
        final groups26 = {
          for (final r in scores)
            if (r['CompNo'] == 26) r['GroupNo'],
        };
        expect(groups26.length, greaterThan(1));
        // 28: the last rounds are drawn but not flown.
        final flown = {
          for (final r in scores)
            if (r['CompNo'] == 28 && r['Updated'] == 'True') r['RoundNo'],
        };
        final drawn = {
          for (final r in scores)
            if (r['CompNo'] == 28) r['RoundNo'],
        };
        expect(drawn.length, greaterThan(flown.length));
        // 39: a pure draw, nothing scored.
        expect(
          scores.where((r) => r['CompNo'] == 39 && r['Updated'] == 'True'),
          isEmpty,
        );
      });

      test('draws_edge_cases holds a flight credited to another round', () {
        final scores = tables('draws_edge_cases.json')['Scores']!;
        final moved = scores.where((r) => r['OriginalRoundNo'] != r['RoundNo']);
        expect(moved, hasLength(1));
      });
    });

    test('the integrity snapshot holds the broken references on purpose', () {
      final t = tables('comps_integrity_cases.json');
      final compNos = [for (final c in t['Comps']!) c['CompNo']];
      expect(compNos.where((n) => n == 9102), hasLength(2));
      final keys = [
        for (final r in t['CompPilots']!) '${r['CompNo']}/${r['PilotNo']}',
      ];
      expect(keys.where((k) => k == '9101/2102'), hasLength(2));
      final pilots = {for (final p in t['Pilots']!) p['PilotNo']};
      expect(
        t['CompPilots']!.where((r) => !pilots.contains(r['PilotNo'])),
        hasLength(1),
      );
    });

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
