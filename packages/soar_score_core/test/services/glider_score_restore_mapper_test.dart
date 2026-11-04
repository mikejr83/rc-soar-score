import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

GliderScoreImportResult _snapshot(String file) {
  final json = jsonDecode(
    File('test/fixtures/gliderscore/$file').readAsStringSync(),
  ) as Map<String, Object?>;
  return GliderScoreImportResult(
    id: Id.create(),
    sourceDbFile: json['sourceDbFile']! as String,
    tables: [
      for (final t
          in (json['tables']! as List<Object?>).cast<Map<String, Object?>>())
        GliderScoreTable(
          name: t['name']! as String,
          rows: (t['rows']! as List<Object?>).cast<Map<String, Object?>>(),
          rowCount: t['rowCount']! as int,
          rowCapExceeded: t['rowCapExceeded']! as bool,
        ),
    ],
  );
}

const _mapper = GliderScoreRestoreMapper();

RestorePlan _plan(String file, int comp) =>
    _mapper.map(_snapshot(file)).firstWhere((p) => p.sourceCompNo == comp);

FlightDraft _flight({
  num? time,
  num? height,
  num? landing,
  num? penalty,
  num? restarted,
  num? raw,
  int round = 1,
  int group = 1,
  int pilot = 7,
}) => FlightDraft(
  taskNo: 1,
  roundNo: round,
  groupNo: group,
  reflightNo: 0,
  sourcePilotNo: pilot,
  scored: true,
  time1Mins: time,
  flightScoreDeduction: height,
  landing: landing,
  penalty: penalty,
  motorRestarted: restarted,
  rawScore: raw,
);

ScoreMappingContext _context({
  int? option = 2,
  num workingTime = 900,
  Map<int, String> keys = const {45: 'points_45'},
}) => ScoreMappingContext(
  restartOption: option,
  workingTimeSeconds: workingTime,
  landing: LandingSelection(
    match: LandingMatch.system,
    systemTable: 'f5jStandard',
    entryKeys: keys,
  ),
);

void main() {
  group('identity and content hash', () {
    test('CompID identifies the competition when there is one', () {
      final p = _plan('reimport_v1.json', 19);
      expect(p.identity.compId, 'FIXTURE19');
      expect(p.identity.key, 'id:fixture19');
      expect(p.identity.dedupeKey, 'gliderscore:id:fixture19');
    });

    test('number, name and date identify one without a CompID', () {
      final p = _plan('reimport_no_compid.json', 19);
      expect(p.identity.hasCompId, isFalse);
      expect(p.identity.key, startsWith('no:19|fixture open 19|20'));
      expect(p.identity.date, matches(RegExp(r'^\d{4}-\d\d-\d\d$')));
    });

    test('the same content from another file has the same hash', () {
      final a = _plan('reimport_v1.json', 19);
      final b = _plan('reimport_v1_copy.json', 19);
      expect(b.contentHash, a.contentHash);
      expect(a.contentHash, hasLength(16));
    });

    test('the same file always gives the same plan and hash', () {
      final a = _mapper.map(_snapshot('scores_reference.json'));
      final b = _mapper.map(_snapshot('scores_reference.json'));
      expect(
        [for (final p in a) p.contentHash],
        [for (final p in b) p.contentHash],
      );
      expect(a.map((p) => p.contentHash).toSet(), hasLength(a.length));
    });

    test('a later version of the competition has another hash', () {
      final v1 = _plan('reimport_v1.json', 19);
      final v2 = _plan('reimport_v2.json', 19);
      expect(v2.contentHash, isNot(v1.contentHash));
      expect(v2.identity, v1.identity);
      expect(v2.flights.length, greaterThan(v1.flights.length));
      expect(
        v2.contest.participants.length,
        v1.contest.participants.length + 1,
      );
    });

    test('one changed landing changes the hash and nothing else', () {
      final v2 = _plan('reimport_v2.json', 19);
      final f = v2.flights.firstWhere(
        (f) => f.roundNo == 1 && f.sourcePilotNo == 109,
      );
      expect(f.components['landing'], 'points_45');
      expect(f.sourceRawScore, 180);
    });

    test('warnings do not take part in the hash', () {
      final plan = _plan('reimport_v1.json', 19);
      expect(plan.warnings, isNotEmpty);
      expect(GliderScoreRestoreMapper.contentHashOf(plan), plan.contentHash);
    });
  });

  group('score values', () {
    const f5j = F5jScoreMapper();

    test('a packed time decodes to seconds', () {
      final v = f5j.mapFlight(
        _flight(time: 1458, height: 166, landing: 45, raw: 860),
        _context(),
      );
      expect(v.kind, RestoredFlightKind.entered);
      expect(v.components, {
        'time_flown': 898,
        'launch_height': 166,
        'landing': 'points_45',
      });
      expect(v.rawComponents['time_1_mins'], 1458);
    });

    test('seconds above 59 refuse the flight', () {
      final v = f5j.mapFlight(_flight(time: 175, height: 10), _context());
      expect(v.refusal, FlightRefusal.timeInvalid);
    });

    test('a time at or over the working time refuses the flight', () {
      final v = f5j.mapFlight(_flight(time: 1500, height: 10), _context());
      expect(v.refusal, FlightRefusal.timeOverWorkingTime);
    });

    test('a time without a height, or a height without a time, refuses', () {
      expect(
        f5j.mapFlight(_flight(time: 300, height: 0), _context()).refusal,
        FlightRefusal.timeHeightMismatch,
      );
      expect(
        f5j.mapFlight(_flight(time: 0, height: 80), _context()).refusal,
        FlightRefusal.timeHeightMismatch,
      );
    });

    test('a fractional height or penalty refuses the flight', () {
      expect(
        f5j.mapFlight(_flight(time: 300, height: 80.5), _context()).refusal,
        FlightRefusal.heightNotWhole,
      );
      expect(
        f5j
            .mapFlight(_flight(time: 300, height: 80, penalty: 2.5), _context())
            .refusal,
        FlightRefusal.penaltyNotWhole,
      );
    });

    test('the penalty is kept as the flight penalty', () {
      final v = f5j.mapFlight(
        _flight(time: 300, height: 80, penalty: 25),
        _context(),
      );
      expect(v.components['flight_penalty'], 25);
    });

    group('zero outcomes, one test per row of the precedence table', () {
      test('restart flag with option 1: a restart zero', () {
        final v = f5j.mapFlight(_flight(restarted: 1), _context(option: 1));
        expect(v.kind, RestoredFlightKind.restartZero);
        expect(v.components['motor_restart'], isTrue);
      });

      test('restart flag with option 2: a restart zero', () {
        final v = f5j.mapFlight(_flight(restarted: 1), _context(option: 2));
        expect(v.kind, RestoredFlightKind.restartZero);
      });

      test('a restart zero keeps the components beside the flag', () {
        final v = f5j.mapFlight(
          _flight(time: 500, height: 90, landing: 45, restarted: 1),
          _context(option: 2),
        );
        expect(v.kind, RestoredFlightKind.restartZero);
        expect(v.components, {
          'time_flown': 300,
          'launch_height': 90,
          'landing': 'points_45',
          'motor_restart': true,
        });
      });

      test('restart flag with option NULL keeps the score and warns', () {
        final v = f5j.mapFlight(
          _flight(time: 1458, height: 166, landing: 45, restarted: 1, raw: 860),
          _context(option: null),
        );
        expect(v.kind, RestoredFlightKind.restartKept);
        expect(v.components.containsKey('motor_restart'), isFalse);
        expect(v.components['time_flown'], 898);
        expect(v.warnings.map((w) => w.code), [
          RestoreWarning.motorRestartKept,
        ]);
        expect(v.rawComponents['motor_restarted'], 1);
      });

      test('restart flag with option 0 keeps the score and warns', () {
        final v = f5j.mapFlight(
          _flight(time: 300, height: 50, restarted: 1),
          _context(option: 0),
        );
        expect(v.kind, RestoredFlightKind.restartKept);
        expect(v.warnings.map((w) => w.code), [
          RestoreWarning.motorRestartKept,
        ]);
      });

      test('nothing recorded: imported as entered, no new reason', () {
        final v = f5j.mapFlight(_flight(raw: 0), _context());
        expect(v.kind, RestoredFlightKind.allZero);
        expect(v.components, isEmpty);
        expect(v.rawComponents['time_1_mins'], isNull);
        expect(v.warnings.map((w) => w.code), [RestoreWarning.allZeroFlight]);
      });

      test('time and height with a raw score of 0: components as is', () {
        final v = f5j.mapFlight(
          _flight(time: 10, height: 166, raw: 0),
          _context(),
        );
        expect(v.kind, RestoredFlightKind.entered);
        expect(v.components, {'time_flown': 10, 'launch_height': 166});
      });

      test('a restart zero with nothing recorded has only the flag', () {
        final v = f5j.mapFlight(_flight(restarted: 1, raw: 0), _context());
        expect(v.components, {'motor_restart': true});
      });

      test('LandingOver75m alone is not a reason', () {
        final f = FlightDraft(
          taskNo: 1,
          roundNo: 1,
          groupNo: 1,
          reflightNo: 0,
          sourcePilotNo: 7,
          scored: true,
          landingOver75m: 1,
          rawScore: 0,
        );
        final v = f5j.mapFlight(f, _context());
        expect(v.kind, RestoredFlightKind.allZero);
        expect(v.components, isEmpty);
        expect(v.rawComponents['landing_over_75m'], 1);
      });
    });

    test('an unresolved landing is left out with a warning', () {
      final v = f5j.mapFlight(
        _flight(time: 300, height: 50, landing: 7),
        _context(),
      );
      expect(v.components.containsKey('landing'), isFalse);
      expect(v.warnings.single.code, RestoreWarning.landingUnresolved);
    });
  });

  group('real flights', () {
    test('restart zeros with option 1 (comp 35)', () {
      final p = _plan('scores_reference.json', 35);
      final restarts = p.flights.where(
        (f) => f.kind == RestoredFlightKind.restartZero,
      );
      expect(restarts, hasLength(3));
      expect(restarts.every((f) => f.sourceRawScore == 0), isTrue);
    });

    test('restart zeros with option 2 and a floored zero (comp 29)', () {
      final p = _plan('scores_reference.json', 29);
      expect(
        p.flights.where((f) => f.kind == RestoredFlightKind.restartZero),
        isNotEmpty,
      );
      final floored = p.flights.where(
        (f) =>
            f.kind == RestoredFlightKind.entered &&
            f.components.containsKey('time_flown') &&
            f.sourceRawScore == 0,
      );
      expect(floored, hasLength(4));
    });

    test(
      'restart option NULL keeps the score of a flagged flight (comp 16)',
      () {
        final p = _plan('scores_reference.json', 16);
        final kept = p.flights.where(
          (f) => f.kind == RestoredFlightKind.restartKept,
        );
        expect(kept, hasLength(1));
        expect(kept.single.sourceRawScore, 860);
        expect(kept.single.components['time_flown'], 898);
        expect(
          p.warnings.map((w) => w.code),
          contains(RestoreWarning.motorRestartKept),
        );
      },
    );

    test('all-zero flights are imported as entered (comp 19)', () {
      final p = _plan('reimport_v2.json', 19);
      final zero = p.flights.where((f) => f.kind == RestoredFlightKind.allZero);
      expect(zero, isNotEmpty);
      expect(zero.every((f) => f.components.isEmpty), isTrue);
      expect(zero.every((f) => f.sourceRawScore == 0), isTrue);
    });

    test('unscored flights are not flights', () {
      final p = _plan('reimport_v1.json', 19);
      expect(p.flights.where((f) => f.roundNo == 3), isEmpty);
      expect(p.trailingUnflownRounds, [3]);
    });
  });

  group('landing tables', () {
    test('GliderScore table 9 matches the F5J standard table', () {
      final l = _plan('scores_reference.json', 19).landing!;
      expect(l.match, LandingMatch.system);
      expect(l.systemTable, 'f5jStandard');
      expect(l.entryKeys[45], 'points_45');
      expect(l.sourceTableNo, 9);
    });

    test('table 5 matches the F5J distance table', () {
      final l = _plan('scores_edge_cases.json', 9305).landing!;
      expect(l.match, LandingMatch.system);
      expect(l.systemTable, 'f5jDistance');
      expect(l.entryKeys, {
        1: 'within_1m',
        2: 'within_2m',
        3: 'within_3m',
        10: 'within_10m',
      });
    });

    test('a table only the competition has is rebuilt', () {
      final p = _plan('scores_edge_cases.json', 9302);
      final l = p.landing!;
      expect(l.match, LandingMatch.reconstructed);
      expect(l.systemTable, isNull);
      expect(l.reconstructedName, 'Example Table');
      expect([for (final e in l.entries) e.points], [37, 22, 11]);
      // The values are not the points, so the scorer picks a distance.
      expect(l.inputUnit, LandingInputUnit.meters);
      expect([for (final e in l.entries) e.label], ['1m', '2m', '3m']);
      expect(l.entryKeys, {1: 'gs_1', 2: 'gs_2', 3: 'gs_3'});
      expect(p.flights.first.components['landing'], 'gs_1');
    });

    test('a value that resolves nowhere is a partial match', () {
      final p = _plan('scores_edge_cases.json', 9301);
      final l = p.landing!;
      expect(l.match, LandingMatch.partial);
      expect(l.unresolved, {7});
      expect(l.systemTable, 'f5jStandard');
      final codes = p.warnings.map((w) => w.code);
      expect(codes, contains(RestoreWarning.landingPartialMatch));
      expect(codes, contains(RestoreWarning.landingUnresolved));
    });

    test('no landing in any flight needs no table', () {
      final l = _plan('draws_reference.json', 39).landing!;
      expect(l.match, LandingMatch.none);
    });
  });

  group('re-flights', () {
    test('a whole-group re-flight goes after the regular groups (comp 21)', () {
      final p = _plan('draws_reference.json', 21);
      expect(p.reflights, hasLength(1));
      final r = p.reflights.single;
      expect(r.roundNo, 8);
      expect(r.sourceGroupNo, 2);
      // Round 8 has two regular groups, so the re-flight is group 3.
      expect(r.flownGroupNo, 3);
      expect(r.members, hasLength(4));
      expect(
        r.members.map((m) => m.role),
        everyElement(ReFlightParticipantRole.groupMember),
      );
      expect([for (final m in r.members) m.position], [1, 2, 3, 4]);
      final flights = p.flights.where((f) => f.isReflight);
      expect(flights, hasLength(4));
      expect(
        flights.every((f) => f.groupNo == 3 && f.sourceGroupNo == 2),
        isTrue,
      );
      expect(flights.every((f) => f.key.contains(',2,1,')), isTrue);
    });

    test('a pilot with no original score is awarded', () {
      final source = _snapshot('draws_reference.json');
      final scores = source.tables.firstWhere((t) => t.name == 'Scores');
      // Pilot 116 did not fly the original flight of round 8.
      final rows = [
        for (final r in scores.rows)
          if (r['CompNo'] == 21 &&
              r['RoundNo'] == 8 &&
              r['PilotNo'] == 116 &&
              r['ReFlightNo'] == 0)
            {...r, 'Updated': 'False'}
          else
            r,
      ];
      final result = GliderScoreImportResult(
        id: source.id,
        sourceDbFile: source.sourceDbFile,
        tables: [
          for (final t in source.tables)
            if (t.name == 'Scores')
              GliderScoreTable(
                name: 'Scores',
                rows: rows,
                rowCount: rows.length,
                rowCapExceeded: false,
              )
            else
              t,
        ],
      );
      final p = _mapper.map(result).firstWhere((p) => p.sourceCompNo == 21);
      final roles = {
        for (final m in p.reflights.single.members) m.sourcePilotNo: m.role,
      };
      expect(roles[116], ReFlightParticipantRole.awarded);
      expect(roles[75], ReFlightParticipantRole.groupMember);
      expect(
        p.warnings.map((w) => w.code),
        contains(RestoreWarning.reflightAwarded),
      );
    });

    test('a repeated pilot in a re-flight group is refused', () {
      final source = _snapshot('draws_reference.json');
      final scores = source.tables.firstWhere((t) => t.name == 'Scores');
      final copy = scores.rows.firstWhere(
        (r) => r['CompNo'] == 21 && r['RoundNo'] == 8 && r['ReFlightNo'] != 0,
      );
      final rows = [
        ...scores.rows,
        {...copy},
      ];
      final result = GliderScoreImportResult(
        id: source.id,
        sourceDbFile: source.sourceDbFile,
        tables: [
          for (final t in source.tables)
            if (t.name == 'Scores')
              GliderScoreTable(
                name: 'Scores',
                rows: rows,
                rowCount: rows.length,
                rowCapExceeded: false,
              )
            else
              t,
        ],
      );
      final p = _mapper.map(result).firstWhere((p) => p.sourceCompNo == 21);
      expect(p.status, RestoreStatus.refused);
      expect(p.reason, RestoreReason.reflightNotWholeGroup);
    });

    test('a re-flight of part of a group is refused', () {
      final p = _plan('scores_edge_cases.json', 9303);
      expect(p.status, RestoreStatus.refused);
      expect(p.reason, RestoreReason.reflightNotWholeGroup);
    });

    test('rounds that overlap between tasks are refused', () {
      final p = _plan('scores_edge_cases.json', 9304);
      expect(p.status, RestoreStatus.refused);
      expect(p.reason, DrawImportReason.taskRangesOverlap);
    });

    test('a moved credit is refused', () {
      final p = _plan('draws_edge_cases.json', 9201);
      expect(p.reason, DrawImportReason.creditMoved);
    });
  });

  group('retirements and rounds', () {
    test('the round after the last scored flight', () {
      final p = _plan('scores_reference.json', 29);
      final rounds = {
        for (final r in p.retirements) r.sourcePilotNo: r.retiredAtRound,
      };
      expect(rounds, {93: 8, 125: 10});
    });

    test('a retired pilot who never scored retires in round 1', () {
      final p = _plan('scores_edge_cases.json', 9302);
      expect(p.retirements.single.sourcePilotNo, 2304);
      expect(p.retirements.single.retiredAtRound, 1);
      expect(
        p.warnings.map((w) => w.code),
        contains(RestoreWarning.retirementInferred),
      );
    });

    test('unflown trailing rounds are listed (comp 28)', () {
      final p = _plan('draws_reference.json', 28);
      expect(p.trailingUnflownRounds, [8, 9, 10]);
      expect(p.completedByDefault, isTrue);
    });

    test('a flown round with unscored flights is partly flown (comp 16)', () {
      final p = _plan('scores_reference.json', 16);
      expect(p.partlyFlownRounds, [2, 3]);
      expect(p.completedByDefault, isFalse);
      expect(p.finalState(completed: false), RestoreFinalState.running);
      expect(p.finalState(completed: true), RestoreFinalState.completed);
    });

    test(
      'unscored flights of a retired pilot do not make a round partly flown',
      () {
        final p = _plan('scores_reference.json', 35);
        expect(p.trailingUnflownRounds, [8]);
        expect(p.partlyFlownRounds, isEmpty);
        expect(p.completedByDefault, isTrue);
      },
    );

    test('a competition with no scored flight stays Ready', () {
      final p = _plan('draws_reference.json', 39);
      expect(p.hasScoredFlights, isFalse);
      expect(p.completedByDefault, isFalse);
      expect(p.finalState(completed: true), RestoreFinalState.ready);
      expect(
        p.warnings.map((w) => w.code),
        contains(RestoreWarning.noScoredFlights),
      );
    });
  });

  group('golden plans', () {
    // Regenerate with `UPDATE_GOLDEN=1 dart test <this file>` after a
    // deliberate change of the mapping.
    void golden(String name, RestorePlan plan) {
      final text =
          '${const JsonEncoder.withIndent('  ').convert({
            ...plan.summary(),
            'landing_entry_keys': {for (final e in (plan.landing?.entryKeys ?? const <int, String>{}).entries) '${e.key}': e.value},
            'flights': [
              for (final f in plan.flights) {'key': f.key, 'group': f.groupNo, 'kind': f.kind.name, 'components': f.components, 'raw_score': f.sourceRawScore},
            ],
            'reflights': [
              for (final r in plan.reflights) {
                  'round': r.roundNo,
                  'source_group': r.sourceGroupNo,
                  'flown_group': r.flownGroupNo,
                  'members': [
                    for (final m in r.members) {'pilot': m.sourcePilotNo, 'role': m.role.name, 'position': m.position},
                  ],
                },
            ],
          })}\n';
      final file = File('test/fixtures/gliderscore/expected/$name');
      if (io.Platform.environment['UPDATE_GOLDEN'] == '1') {
        file.writeAsStringSync(text);
      }
      expect(file.readAsStringSync(), text);
    }

    test('comp 19, later version', () {
      golden('restore_comp_19_v2.json', _plan('reimport_v2.json', 19));
    });

    test('comp 21 with its re-flight', () {
      golden('restore_comp_21.json', _plan('draws_reference.json', 21));
    });

    test('comp 35 with restart zeros and an unflown last round', () {
      golden('restore_comp_35.json', _plan('scores_reference.json', 35));
    });
  });

  group('odd input', () {
    test('an empty file gives no plans', () {
      final empty = GliderScoreImportResult(
        id: Id.create(),
        sourceDbFile: 'x.mdb',
        tables: const [],
      );
      expect(_mapper.map(empty), isEmpty);
    });

    test('a class without a restore is refused with the contest reason', () {
      final plans = _mapper.map(_snapshot('comps_reference.json'));
      final f3j = plans.firstWhere((p) => p.contest.sourceClass == 'F3J');
      expect(f3j.status, RestoreStatus.refused);
      expect(f3j.reason, ContestImportReason.classNotSupportedYet);
    });

    test('a file without Scores is refused, not thrown at', () {
      final p = _plan('comps_reference.json', 22);
      expect(p.status, RestoreStatus.refused);
      expect(p.reason, DrawImportReason.scoresUnavailable);
    });

    test('a file with unusable score cells is refused with the flights', () {
      final source = _snapshot('reimport_v2.json');
      final scores = source.tables.firstWhere((t) => t.name == 'Scores');
      final rows = [
        for (final r in scores.rows)
          if (r['RoundNo'] == 1 && r['PilotNo'] == 109)
            {...r, 'Time1Mins': 175}
          else
            r,
      ];
      final result = GliderScoreImportResult(
        id: source.id,
        sourceDbFile: source.sourceDbFile,
        tables: [
          for (final t in source.tables)
            if (t.name == 'Scores')
              GliderScoreTable(
                name: 'Scores',
                rows: rows,
                rowCount: rows.length,
                rowCapExceeded: false,
              )
            else
              t,
        ],
      );
      final p = _mapper.map(result).single;
      expect(p.reason, RestoreReason.flightNotRepresentable);
      expect(p.reasonDetail, contains('round 1 group 1 pilot 109'));
      expect(p.reasonDetail, contains(FlightRefusal.timeInvalid));
    });
  });
}
