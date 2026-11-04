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
      'scores_reference.json',
      'scores_edge_cases.json',
      'reimport_v1.json',
      'reimport_v2.json',
      'reimport_v1_copy.json',
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
      'LndgNames.Name': RegExp(
        r'^(None|FAI 15 Metre Tape|F3J Enter Dist|F3J Enter Points|'
        r'F3J Enter Pts to 2m|F5J Enter Distance|ALES Landing|F3J Enter Cms|'
        r'F5B Enter Distance|F5J Enter Points|FAI 15m Points|Example Table)$',
      ),
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
      'LndgNames': {'LndgNo'},
      'LndgPoints': {'LndgNo', 'Distance', 'Points'},
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
      'scores_reference.json',
      'scores_edge_cases.json',
      'reimport_v1.json',
      'reimport_v2.json',
      'reimport_v1_copy.json',
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

    group('score fixtures (phase D, #768)', () {
      bool scored(Map<String, Object?> r) => r['Updated'] == 'True';
      num n(Map<String, Object?> r, String k) => (r[k] as num?) ?? 0;

      test('the size ceiling holds for all snapshots together', () {
        const ceiling = 900 * 1024;
        var total = 0;
        for (final f in Directory('test/fixtures/gliderscore').listSync()) {
          if (f is File && f.path.endsWith('.json')) {
            total += f.lengthSync();
          }
        }
        expect(total, lessThan(ceiling));
      });

      test('the reference holds the scenarios of the score plan', () {
        final t = tables('scores_reference.json');
        final scores = t['Scores']!;
        final dur = {for (final d in t['Dur']!) d['CompNo']! as int: d};
        final comps = {for (final c in t['Comps']!) c['CompNo']! as int: c};
        expect(comps.keys.toSet(), {10, 16, 19, 29, 35});

        // Motor restart option 1 (35), 2 (29) and NULL (16, with a flagged
        // flight that kept its score).
        expect(dur[35]!, containsPair('F5JMotorRestartOption', 1));
        expect(dur[29]!, containsPair('F5JMotorRestartOption', 2));
        expect(dur[16]!.containsKey('F5JMotorRestartOption'), isFalse);
        Iterable<Map<String, Object?>> restarted(int comp) => scores.where(
          (r) => r['CompNo'] == comp && n(r, 'F5JMotorReStarted') == 1,
        );
        for (final comp in [35, 29]) {
          expect(restarted(comp), isNotEmpty);
          expect(restarted(comp).every((r) => n(r, 'RawScore') == 0), isTrue);
        }
        expect(restarted(16).any((r) => n(r, 'RawScore') > 0), isTrue);

        // A floored zero: a time and a launch height, and a raw score of 0.
        expect(
          scores.where(
            (r) =>
                r['CompNo'] == 29 &&
                scored(r) &&
                n(r, 'Time1Mins') > 0 &&
                n(r, 'FlightScoreDeduction') > 0 &&
                n(r, 'RawScore') == 0,
          ),
          isNotEmpty,
        );
        // All-zero flights marked as entered.
        expect(
          scores.where(
            (r) =>
                scored(r) &&
                n(r, 'Time1Mins') == 0 &&
                n(r, 'Landing') == 0 &&
                n(r, 'FlightScoreDeduction') == 0 &&
                n(r, 'F5JMotorReStarted') == 0,
          ),
          isNotEmpty,
        );
        // A retired pilot with unflown later rounds (35) and a last round
        // that is entirely unflown.
        expect(
          t['CompPilots']!.where((r) => r['CompNo'] == 35 && r['Retired'] == 1),
          isNotEmpty,
        );
        final lastRound35 = scores
            .where((r) => r['CompNo'] == 35)
            .map((r) => r['RoundNo']! as int)
            .reduce((a, b) => a > b ? a : b);
        expect(
          scores.where(
            (r) =>
                r['CompNo'] == 35 && r['RoundNo'] == lastRound35 && scored(r),
          ),
          isEmpty,
        );
        // A flown round with unscored flights (16, 19, 35).
        for (final comp in [16, 19, 35]) {
          final byRound = <Object?, Set<bool>>{};
          for (final r in scores.where((r) => r['CompNo'] == comp)) {
            (byRound[r['RoundNo']] ??= {}).add(scored(r));
          }
          expect(
            byRound.values.where((v) => v.length == 2),
            isNotEmpty,
            reason: 'comp $comp has a partly flown round',
          );
        }
        // 10 has no CompID and uses landing table 5, with all rounds flown;
        // the other competitions carry a CompID.
        expect(comps[10]!.containsKey('CompID'), isFalse);
        expect(dur[10]!, containsPair('durLndg', 5));
        expect(scores.where((r) => r['CompNo'] == 10).every(scored), isTrue);
        for (final comp in [16, 19, 29, 35]) {
          expect(comps[comp]!['CompID'], 'FIXTURE$comp');
        }
        // The landing tables the competitions use are carried.
        expect({for (final r in t['LndgNames']!) r['LndgNo']}, {5, 9});
        expect(t['LndgPoints']!.length, 20);
      });

      test('the edge cases hold a partial match, a custom table, a subset '
          're-flight and overlapping tasks', () {
        final t = tables('scores_edge_cases.json');
        final scores = t['Scores']!;
        final table9 = {
          for (final r in t['LndgPoints']!)
            if (r['LndgNo'] == 9) r['Distance'],
        };
        final landings9301 = {
          for (final r in scores)
            if (r['CompNo'] == 9301) r['Landing'],
        };
        expect(landings9301.difference(table9), {7});
        expect(
          t['Dur']!.firstWhere((d) => d['CompNo'] == 9302),
          containsPair('durLndg', 11),
        );
        expect({for (final r in t['LndgNames']!) r['LndgNo']}, {9, 11});
        expect(
          t['CompPilots']!.where(
            (r) => r['CompNo'] == 9302 && r['Retired'] == 1,
          ),
          hasLength(1),
        );
        final reflights = scores.where(
          (r) => r['CompNo'] == 9303 && r['ReFlightNo'] == 1,
        );
        expect(reflights, hasLength(2));
        expect(
          scores.where((r) => r['CompNo'] == 9303 && r['ReFlightNo'] == 0),
          hasLength(4),
        );
        final rounds = {
          for (final task in [1, 2])
            task: {
              for (final r in scores)
                if (r['CompNo'] == 9304 && r['TaskNo'] == task) r['RoundNo'],
            },
        };
        expect(rounds[1]!.intersection(rounds[2]!), isNotEmpty);
      });

      test('the re-import files differ the way the plan says', () {
        final v1 = tables('reimport_v1.json');
        final v2 = tables('reimport_v2.json');
        final copy = tables('reimport_v1_copy.json');
        // The copy is the same content from another file.
        expect(copy, equals(v1));
        expect(
          _load('reimport_v1_copy.json')['id'],
          isNot(_load('reimport_v1.json')['id']),
        );
        expect(
          _load('reimport_v1_copy.json')['sourceDbFile'],
          isNot(_load('reimport_v1.json')['sourceDbFile']),
        );
        // Everything of the early file has the same identity as the later.
        expect(v1['Comps'], equals(v2['Comps']));
        // Round 3 is drawn but unscored early, scored later.
        bool round3Scored(Map<String, List<Map<String, Object?>>> t) =>
            t['Scores']!.any((r) => r['RoundNo'] == 3 && scored(r));
        expect(round3Scored(v1), isFalse);
        expect(round3Scored(v2), isTrue);
        // One pilot is added in the later file.
        expect(v2['CompPilots']!.length, v1['CompPilots']!.length + 1);
        // One landing changed (50 to 45) with the raw score lowered by 5.
        Map<String, Object?> changed(
          Map<String, List<Map<String, Object?>>> t,
        ) => t['Scores']!.firstWhere(
          (r) => r['RoundNo'] == 1 && r['PilotNo'] == 109,
        );
        expect(changed(v1)['Landing'], 50);
        expect(changed(v2)['Landing'], 45);
        expect(n(changed(v1), 'RawScore') - n(changed(v2), 'RawScore'), 5);
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
