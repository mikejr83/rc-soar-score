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

GliderScoreImportResult _tables(Map<String, List<Map<String, Object?>>> t) =>
    GliderScoreImportResult(
      id: Id.create(),
      sourceDbFile: 'x.mdb',
      tables: [
        for (final e in t.entries)
          GliderScoreTable(
            name: e.key,
            rows: e.value,
            rowCount: e.value.length,
            rowCapExceeded: false,
          ),
      ],
    );

const _mapper = GliderScoreContestMapper();

CompetitionImportDraft _map(String file) => _mapper.map(_snapshot(file));

ContestImportDraft _comp(CompetitionImportDraft d, int no) =>
    d.contests.singleWhere((c) => c.sourceCompNo == no);

Set<String> _codes(ContestImportDraft c) => {
  for (final w in c.warnings) w.code,
};

/// A competition with the smallest set of columns, for single-rule tests.
GliderScoreImportResult _one({
  Map<String, Object?> comp = const {},
  Map<String, Object?> config = const {},
  List<Map<String, Object?>> members = const [],
  List<Map<String, Object?>> pilots = const [],
}) => _tables({
  'Comps': [
    {
      'CompNo': 1,
      'CompName': 'C',
      'GSCompClass': 'F5J',
      'CompDate': '06/14/26 00:00:00',
      ...comp,
    },
  ],
  'CompPilots': [
    for (final m in members) {'CompNo': 1, ...m},
  ],
  'Pilots': [
    for (final p in pilots)
      {'FirstName': 'A${p['PilotNo']}', 'LastName': 'B${p['PilotNo']}', ...p},
  ],
  'Dur': [
    {'CompNo': 1, 'durTargetTime': 600, ...config},
  ],
});

ContestImportDraft _single(GliderScoreImportResult r) =>
    _mapper.map(r).contests.single;

Map<String, Object?> _golden(ContestImportDraft c) => {
  'sourceCompNo': c.sourceCompNo,
  'sourceClass': c.sourceClass,
  'status': c.status.name,
  'reason': c.reason,
  'name': c.name,
  'host': c.host,
  'startDate': c.startDate?.toIso8601String(),
  'disciplineType': c.disciplineType,
  'config': c.config?.toJson(),
  'defaultedSettings': c.defaultedSettings,
  'sourceLandingTableNo': c.sourceLandingTableNo,
  'excludedTestUsers': c.excludedTestUsers,
  'teams': [
    for (final t in c.teams) {'sourceTeamNo': t.sourceTeamNo, 'name': t.name},
  ],
  'participants': [
    for (final p in c.participants)
      {
        'sourcePilotNo': p.sourcePilotNo,
        'role': p.role.name,
        'sourceRole': p.sourceRole,
        'retired': p.retired,
        'participantNumber': p.participantNumber,
        'classification': p.classification,
        'sourceTeamNo': p.sourceTeamNo,
        'modelName': p.modelName,
        'modelId': p.modelId,
      },
  ],
  'skippedParticipants': [
    for (final s in c.skippedParticipants)
      {'sourcePilotNo': s.sourcePilotNo, 'reason': s.reason},
  ],
  'warnings': [
    for (final w in c.warnings)
      {'code': w.code, 'sourcePilotNo': w.sourcePilotNo, 'detail': w.detail},
  ],
};

void main() {
  group('golden', () {
    test('real comp 22 maps to the checked-in draft', () {
      final actual = const JsonEncoder.withIndent('  ')
          .convert(_golden(_comp(_map('comps_reference.json'), 22)));
      final file = File(
        'test/fixtures/gliderscore/expected/comp_22_draft.json',
      );
      if (io.Platform.environment['UPDATE_GOLDEN'] == '1') {
        file.writeAsStringSync('$actual\n');
      }
      expect(jsonDecode(actual), jsonDecode(file.readAsStringSync()));
    });

    test('hand-built comp 9001 (teams, drops, classes, models)', () {
      final actual = const JsonEncoder.withIndent('  ')
          .convert(_golden(_comp(_map('comps_edge_cases.json'), 9001)));
      final file = File(
        'test/fixtures/gliderscore/expected/comp_9001_draft.json',
      );
      if (io.Platform.environment['UPDATE_GOLDEN'] == '1') {
        file.writeAsStringSync('$actual\n');
      }
      expect(jsonDecode(actual), jsonDecode(file.readAsStringSync()));
    });
  });

  group('classes', () {
    test('the reference file: F5J importable, F3J and F5L skipped', () {
      final d = _map('comps_reference.json');
      expect(
        [for (final c in d.contests) c.sourceCompNo],
        [20, 21, 22, 39, 40],
      );
      for (final no in [21, 22, 39]) {
        expect(_comp(d, no).status, ContestImportStatus.importable);
        expect(_comp(d, no).disciplineType, 'F5J');
      }
      expect(_comp(d, 20).status, ContestImportStatus.skipped);
      expect(_comp(d, 20).reason, ContestImportReason.classNotSupportedYet);
      expect(_comp(d, 40).status, ContestImportStatus.skipped);
      expect(_comp(d, 40).reason, ContestImportReason.classOutOfScope);
      expect(_comp(d, 20).participants, isEmpty);
    });

    test('an unknown class is skipped with its own reason', () {
      final c = _comp(_map('comps_edge_cases.json'), 9004);
      expect(c.status, ContestImportStatus.skipped);
      expect(c.reason, ContestImportReason.classUnknown);
      expect(c.reasonDetail, 'F3Z');
    });

    test('a blank class is unknown', () {
      final c = _single(_one(comp: {'GSCompClass': ' '}));
      expect(c.reason, ContestImportReason.classUnknown);
      expect(c.reasonDetail, isNull);
    });

    test('a registered class mapper is used, nothing else changes', () {
      final r = _one(comp: {'GSCompClass': 'F3J'});
      const f3j = _FakeMapper();
      final c = const GliderScoreContestMapper(
        classMappers: {'F5J': F5jClassMapper(), 'F3J': f3j},
      ).map(r).contests.single;
      expect(c.status, ContestImportStatus.importable);
      expect(c.disciplineType, 'F3J');
      expect(c.config!.discipline, {'working_time': 1});
    });

    test('every skipped class has a reason code', () {
      for (final reason in GliderScoreContestMapper.skippedClasses.values) {
        expect({
          ContestImportReason.classNotSupportedYet,
          ContestImportReason.classOutOfScope,
        }, contains(reason));
      }
    });
  });

  group('blocked', () {
    test('a competition with no Dur row is blocked', () {
      final c = _comp(_map('comps_edge_cases.json'), 9003);
      expect(c.status, ContestImportStatus.blocked);
      expect(c.reason, ContestImportReason.configMissing);
    });

    test('no usable date blocks, and the raw value is kept', () {
      final c = _single(_one(comp: {'CompDate': 'someday'}));
      expect(c.status, ContestImportStatus.blocked);
      expect(c.reason, ContestImportReason.dateMissing);
      expect(c.reasonDetail, 'someday');
      expect(
        _single(_one(comp: {'CompDate': '02/30/26 00:00:00'})).reason,
        ContestImportReason.dateMissing,
      );
    });

    test('team protection without teams is not mapped', () {
      final c = _single(_one(comp: {'UseTeams': 0, 'UseTeamProtection': 1}));
      // Protection without teams is simply not mapped (teams are off).
      expect(c.status, ContestImportStatus.importable);
    });
  });

  group('dates', () {
    test('US and ISO forms, two-digit years', () {
      DateTime? d(Object? v) => GliderScoreContestMapper.parseDate(v);
      expect(d('03/18/22 00:00:00'), DateTime.utc(2022, 3, 18));
      expect(d('3/8/2022'), DateTime.utc(2022, 3, 8));
      expect(d('01/02/99 00:00:00'), DateTime.utc(1999, 1, 2));
      expect(d('2026-06-14 00:00:00'), DateTime.utc(2026, 6, 14));
      expect(d('2026-06-14T00:00:00'), DateTime.utc(2026, 6, 14));
      expect(d(null), isNull);
      expect(d(''), isNull);
      expect(d('13/01/22 00:00:00'), isNull);
    });
  });

  group('configuration', () {
    test('core options and discipline settings of an F5J comp', () {
      final c = _comp(_map('comps_reference.json'), 22);
      expect(c.config!.core, containsPair('group_score_mode', 'Normalized'));
      expect(c.config!.core, containsPair('rounding_mode', 'Truncate'));
      expect(c.config!.core, containsPair('decimal_places', 2));
      expect(c.config!.core, containsPair('drop_after_rounds', [5]));
      expect(c.config!.core, containsPair('lane_mode', 'None'));
      expect(c.config!.discipline, {
        'working_time': 600,
        'points_per_second': 1.0,
        'fractional_seconds': 0,
        'reference_launch_height': 200,
        'minor_penalty_per_meter': 0.5,
        'major_penalty_per_meter': 3.0,
        'motor_restart_mode': 'not_allowed',
      });
      expect(c.config!.coreOptions.decimalPlaces, 2);
      expect(c.defaultedSettings, ['discipline.landing_table']);
      expect(c.sourceLandingTableNo, 9);
      expect(_codes(c), contains(ContestImportWarning.landingTableNotImported));
    });

    test('motor restart 0, 1 and 2 map to the mode names', () {
      String? mode(Object? v) =>
          _single(_one(config: {'F5JMotorRestartOption': v}))
                  .config!
                  .discipline['motor_restart_mode']
              as String?;
      expect(mode(0), 'not_allowed');
      expect(mode(1), 'non_droppable');
      expect(mode(2), 'allowed');
    });

    test('an empty motor restart option keeps the default and warns', () {
      final c = _single(_one());
      expect(c.config!.discipline, isNot(contains('motor_restart_mode')));
      expect(c.defaultedSettings, contains('discipline.motor_restart_mode'));
      expect(_codes(c), contains(ContestImportWarning.motorRestartUnset));
    });

    test('an out-of-range option is left at the default with a warning', () {
      final c = _single(
        _one(
          comp: {
            'GroupScoreOption': 7,
            'RoundOrTruncate': 5,
            'DrawMode': 3,
            'GroupScoreDecimals': 9,
          },
          config: {'F5JMotorRestartOption': 9, 'durDecimalsForTiming': 8},
        ),
      );
      expect(c.config!.core.keys, isNot(contains('group_score_mode')));
      expect(c.config!.core.keys, isNot(contains('rounding_mode')));
      expect(c.config!.core.keys, isNot(contains('draw_mode')));
      expect(c.config!.core.keys, isNot(contains('decimal_places')));
      expect(c.config!.discipline.keys, isNot(contains('fractional_seconds')));
      expect(
        c.warnings.where(
          (w) => w.code == ContestImportWarning.settingOutOfRange,
        ),
        hasLength(6),
      );
    });

    test('group score option 2 is Time', () {
      final c = _single(_one(comp: {'GroupScoreOption': 2}));
      expect(c.config!.core['group_score_mode'], 'Time');
    });

    test('a fractional reference height is rounded with a warning', () {
      final c = _single(_one(config: {'durRefHeight': 150.4}));
      expect(c.config!.discipline['reference_launch_height'], 150);
      expect(_codes(c), contains(ContestImportWarning.referenceHeightRounded));
    });

    test('lanes become a mode and the count is only reported', () {
      final c = _single(_one(config: {'durNbrOfLanes': 6}));
      expect(c.config!.core['lane_mode'], 'Random');
      expect(
        c.warnings
            .singleWhere(
              (w) => w.code == ContestImportWarning.lanesCountNotStored,
            )
            .detail,
        '6',
      );
    });

    test('prelim comps and locks are reported, not imported', () {
      final c = _single(_one(comp: {'PrelimCompNo': 3, 'ScoresLocked': 1}));
      expect(
        _codes(c),
        containsAll([
          ContestImportWarning.prelimNotImported,
          ContestImportWarning.scoresLockedNotImported,
        ]),
      );
    });

    test('teams on: count and protection, with a bad count defaulted', () {
      final c = _single(
        _one(
          comp: {'UseTeams': 1, 'NbrForTeamScore': 0, 'UseTeamProtection': 1},
        ),
      );
      expect(c.config!.core['teams_enabled'], true);
      expect(c.config!.core['team_pilot_count'], 1);
      expect(c.config!.core['team_protection'], true);
      expect(_codes(c), contains(ContestImportWarning.teamPilotCountDefaulted));
    });
  });

  group('drops', () {
    List<Object?>? drops(Map<String, Object?> comp) =>
        _single(_one(comp: comp)).config!.core['drop_after_rounds']
            as List<Object?>?;

    test('99 means none', () {
      expect(
        drops({
          'Drop1AtRound': 99,
          'Drop2AtRound': 99,
          'Drop3AtRound': 99,
          'Drop4AtRound': 99,
          'Drop5AtRound': 99,
        }),
        isEmpty,
      );
    });

    test('five drops keep the lowest two and warn', () {
      final c = _single(
        _one(
          comp: {
            'Drop1AtRound': 15,
            'Drop2AtRound': 3,
            'Drop3AtRound': 12,
            'Drop4AtRound': 6,
            'Drop5AtRound': 9,
          },
        ),
      );
      expect(c.config!.core['drop_after_rounds'], [3, 6]);
      expect(
        c.warnings
            .singleWhere((w) => w.code == ContestImportWarning.dropsDiscarded)
            .detail,
        'kept 3,6; discarded 9,12,15',
      );
    });

    test('duplicates collapse and invalid values are reported', () {
      final c = _single(
        _one(comp: {'Drop1AtRound': 5, 'Drop2AtRound': 5, 'Drop3AtRound': 0}),
      );
      expect(c.config!.core['drop_after_rounds'], [5]);
      expect(_codes(c), contains(ContestImportWarning.dropInvalid));
    });

    test('no drop column at all leaves the default', () {
      final c = _single(_one());
      expect(c.config!.core.keys, isNot(contains('drop_after_rounds')));
      expect(c.defaultedSettings, contains('core.drop_after_rounds'));
    });
  });

  group('participants', () {
    test('comp 22: 31 plain pilots, no extras', () {
      final c = _comp(_map('comps_reference.json'), 22);
      expect(c.participants.length + c.excludedTestUsers, 31);
      expect(c.participants.every((p) => p.role == ImportedRole.pilot), isTrue);
      expect(c.participants.every((p) => p.participantNumber == null), isTrue);
      expect(c.teams, isEmpty);
    });

    test('test pilots are left out and counted', () {
      final r = _one(
        members: [
          {'PilotNo': 1},
          {'PilotNo': 2},
        ],
        pilots: [
          {'PilotNo': 1},
          {'PilotNo': 2, 'LastName': 'ZZtest'},
        ],
      );
      final c = _single(r);
      expect([for (final p in c.participants) p.sourcePilotNo], [1]);
      expect(c.excludedTestUsers, 1);
      expect(c.skippedParticipants, isEmpty);
    });

    test('a participant with no Pilots row, or no name, is skipped', () {
      final c = _single(
        _one(
          members: [
            {'PilotNo': 1},
            {'PilotNo': 2},
            {'PilotNo': 3},
          ],
          pilots: [
            {'PilotNo': 1},
            {'PilotNo': 3, 'FirstName': ' '},
          ],
        ),
      );
      expect(
        {for (final s in c.skippedParticipants) s.sourcePilotNo: s.reason},
        {
          2: ContestImportWarning.participantPilotMissing,
          3: ContestImportWarning.participantPilotUnusable,
        },
      );
    });

    test('integrity snapshot: duplicates and missing pilots are reported', () {
      final d = _map('comps_integrity_cases.json');
      expect(d.contests.map((c) => c.sourceCompNo), [9101, 9102]);
      expect(
        d.warnings.where(
          (w) => w.code == ContestImportWarning.duplicateCompNumber,
        ),
        hasLength(1),
      );
      final c = _comp(d, 9101);
      expect([for (final p in c.participants) p.sourcePilotNo], [2101, 2102]);
      expect(
        {for (final s in c.skippedParticipants) s.sourcePilotNo: s.reason},
        {
          2102: ContestImportWarning.duplicateParticipation,
          2999: ContestImportWarning.participantPilotMissing,
        },
      );
    });

    test('a row with no PilotNo is skipped', () {
      final c = _single(
        _one(
          members: [
            {'Role': 'Plt'},
          ],
        ),
      );
      expect(c.skippedParticipants.single.sourcePilotNo, isNull);
    });

    test('a comp with no participants still imports, with a warning', () {
      final c = _single(_one());
      expect(c.status, ContestImportStatus.importable);
      expect(_codes(c), contains(ContestImportWarning.noParticipants));
    });
  });

  group('roles', () {
    final all = _comp(_map('comps_edge_cases.json'), 9002);

    test('every role maps, composites degrade to Pilot with a warning', () {
      final roles = {for (final p in all.participants) p.sourcePilotNo: p.role};
      expect(roles, {
        2001: ImportedRole.pilot,
        2002: ImportedRole.pilot,
        2003: ImportedRole.pilot,
        2004: ImportedRole.pilot, // TM/Plt
        2005: ImportedRole.pilot, // CD/Plt
        2006: ImportedRole.competitionDirector,
        2007: ImportedRole.helper,
        2008: ImportedRole.teamManager,
      });
      final composite = all.warnings.where(
        (w) => w.code == ContestImportWarning.roleComposite,
      );
      expect(
        {for (final w in composite) w.sourcePilotNo: w.detail},
        {2004: 'TM/Plt', 2005: 'CD/Plt'},
      );
      expect(
        all.participants.firstWhere((p) => p.sourcePilotNo == 2004).sourceRole,
        'TM/Plt',
      );
    });

    test('only fliers fly', () {
      expect(ImportedRole.pilot.flies, isTrue);
      expect(ImportedRole.helper.flies, isFalse);
      expect(ImportedRole.teamManager.flies, isFalse);
      expect(ImportedRole.competitionDirector.flies, isFalse);
    });

    test('retired pilots stay active and are reported', () {
      final retired = all.participants.where((p) => p.retired);
      expect([for (final p in retired) p.sourcePilotNo], [2002, 2003]);
      expect(
        all.warnings.where(
          (w) => w.code == ContestImportWarning.retiredKeptActive,
        ),
        hasLength(2),
      );
    });

    test('roles in a comp that has the flag off are reported once', () {
      final c = _single(
        _one(
          members: [
            {'PilotNo': 1, 'Role': 'Hlp'},
            {'PilotNo': 2, 'Role': 'TM'},
          ],
          pilots: [
            {'PilotNo': 1},
            {'PilotNo': 2},
          ],
        ),
      );
      expect(
        c.warnings.where(
          (w) => w.code == ContestImportWarning.rolesPresentFlagOff,
        ),
        hasLength(1),
      );
    });

    test('an unknown role code falls back by IsPilot', () {
      final c = _single(
        _one(
          members: [
            {'PilotNo': 1, 'Role': 'Zzz', 'IsPilot': 0},
            {'PilotNo': 2, 'Role': 'Zzz'},
          ],
          pilots: [
            {'PilotNo': 1},
            {'PilotNo': 2},
          ],
        ),
      );
      expect(
        [for (final p in c.participants) p.role],
        [ImportedRole.helper, ImportedRole.pilot],
      );
      expect(
        c.warnings.where((w) => w.code == ContestImportWarning.roleUnknown),
        hasLength(2),
      );
    });
  });

  group('teams, numbers, classes, models', () {
    final c = _comp(_map('comps_edge_cases.json'), 9001);

    test(
      'teams are generated with a warning and members keep their number',
      () {
        expect(
          [for (final t in c.teams) (t.sourceTeamNo, t.name)],
          [(1, 'Team 1'), (2, 'Team 2')],
        );
        expect(c.participants.where((p) => p.sourceTeamNo == 1), hasLength(4));
        expect(_codes(c), contains(ContestImportWarning.teamNamesGenerated));
        expect(c.config!.core['team_pilot_count'], 2);
        expect(c.config!.core['team_protection'], true);
      },
    );

    test('team numbers are ignored when teams are off', () {
      final r = _one(
        comp: {'UseTeams': 0},
        members: [
          {'PilotNo': 1, 'Team': 4},
        ],
        pilots: [
          {'PilotNo': 1},
        ],
      );
      final d = _single(r);
      expect(d.teams, isEmpty);
      expect(d.participants.single.sourceTeamNo, isNull);
      expect(_codes(d), contains(ContestImportWarning.teamIgnored));
    });

    test('omit-from-team-score is reported', () {
      expect(
        c.warnings.where(
          (w) => w.code == ContestImportWarning.omitFromTeamScoreDropped,
        ),
        hasLength(1),
      );
    });

    test('start numbers are kept, duplicates and zeros renumbered', () {
      final nums = {
        for (final p in c.participants)
          if (p.participantNumber != null) p.sourcePilotNo: p.participantNumber,
      };
      expect(nums, {2001: 1, 2002: 2, 2003: 3, 2004: 4, 2005: 5, 2006: 6});
      final r = _one(
        comp: {'UsePilotNumbering': 1},
        members: [
          {'PilotNo': 5, 'StartNo': 3},
          {'PilotNo': 6, 'StartNo': 3},
          {'PilotNo': 7, 'StartNo': 0},
          {'PilotNo': 8, 'StartNo': 1},
          {'PilotNo': 9, 'Role': 'Hlp', 'StartNo': 0},
        ],
        pilots: [
          for (final n in [5, 6, 7, 8, 9]) {'PilotNo': n},
        ],
      );
      final d = _single(r);
      expect(
        {for (final p in d.participants) p.sourcePilotNo: p.participantNumber},
        {5: 3, 6: 2, 7: 4, 8: 1, 9: null},
      );
      expect(
        d.warnings
            .singleWhere(
              (w) => w.code == ContestImportWarning.startNumberDuplicate,
            )
            .sourcePilotNo,
        6,
      );
    });

    test('numbers are not imported when numbering is off', () {
      final d = _single(
        _one(
          members: [
            {'PilotNo': 1, 'StartNo': 7},
          ],
          pilots: [
            {'PilotNo': 1},
          ],
        ),
      );
      expect(d.participants.single.participantNumber, isNull);
    });

    test('classes and models are imported for fliers only, when on', () {
      final p = {for (final p in c.participants) p.sourcePilotNo: p};
      expect(p[2001]!.classification, 'Sr');
      expect(p[2003]!.classification, 'Jr');
      expect(p[2001]!.modelName, 'Alpha Glider');
      expect(p[2007]!.classification, isNull);
      expect(p[2007]!.modelName, isNull);
      expect(p[2001]!.modelId, isNull, reason: 'ModelData -1 is no id');
    });

    test('a real ModelData becomes the model id', () {
      final d = _single(
        _one(
          comp: {'UseModels': 1},
          members: [
            {'PilotNo': 1, 'Model': 'Zephyr', 'ModelData': 'ABC123'},
          ],
          pilots: [
            {'PilotNo': 1},
          ],
        ),
      );
      expect(d.participants.single.modelName, 'Zephyr');
      expect(d.participants.single.modelId, 'ABC123');
    });

    test('classes and models are dropped with one warning when off', () {
      final d = _single(
        _one(
          members: [
            {'PilotNo': 1, 'Model': 'A', 'PilotClass': 'Sr'},
            {'PilotNo': 2, 'Model': 'B', 'PilotClass': 'Jr'},
          ],
          pilots: [
            {'PilotNo': 1},
            {'PilotNo': 2},
          ],
        ),
      );
      expect(d.participants.every((p) => p.modelName == null), isTrue);
      expect(d.participants.every((p) => p.classification == null), isTrue);
      expect(
        d.warnings.where(
          (w) => w.code == ContestImportWarning.modelsDisabledDropped,
        ),
        hasLength(1),
      );
      expect(
        d.warnings.where(
          (w) => w.code == ContestImportWarning.classesDisabledDropped,
        ),
        hasLength(1),
      );
    });
  });

  group('file level', () {
    test('every optional column missing still maps comp 22', () {
      final d = _map('comps_missing_columns.json');
      final c = d.contests.single;
      expect(c.status, ContestImportStatus.importable);
      expect(c.name, 'Fixture Open 22');
      expect(c.host, isNull);
      expect(c.participants, hasLength(31));
      expect(c.config!.discipline, {'working_time': 600});
      expect(c.config!.core, {
        'teams_enabled': false,
        'roles_enabled': false,
        'classes_enabled': false,
        'models_enabled': false,
        'participant_numbers_enabled': false,
        'lane_mode': 'None',
      });
      expect(
        c.defaultedSettings,
        containsAll([
          'core.group_score_mode',
          'core.rounding_mode',
          'core.decimal_places',
          'core.drop_after_rounds',
          'discipline.points_per_second',
        ]),
      );
      expect(d.sourceVersion, isNull);
      expect(d.warnings.map((w) => w.code), [
        ContestImportWarning.dbVersionUntested,
      ]);
    });

    test('a known DBVersion does not warn, an unknown one does', () {
      expect(_map('comps_reference.json').sourceVersion, '6.78');
      expect(_map('comps_reference.json').warnings, isEmpty);
      final r = _tables({
        'DBParams': [
          {'Property': 'DBVersion', 'PRValue': '7.01'},
        ],
        'Comps': [],
      });
      final d = _mapper.map(r);
      expect(d.warnings.single.code, ContestImportWarning.dbVersionUntested);
      expect(d.warnings.single.detail, '7.01');
    });

    test('no Comps table gives an empty draft with a warning', () {
      final d = _mapper.map(_tables({'Pilots': []}));
      expect(d.contests, isEmpty);
      expect(
        d.warnings.map((w) => w.code),
        contains(ContestImportWarning.compsTableMissing),
      );
    });

    test('a capped table is reported', () {
      final r = GliderScoreImportResult(
        id: Id.create(),
        sourceDbFile: 'x.mdb',
        tables: const [
          GliderScoreTable(
            name: 'CompPilots',
            rows: [],
            rowCount: 900,
            rowCapExceeded: true,
          ),
          GliderScoreTable(
            name: 'Comps',
            rows: [],
            rowCount: 0,
            rowCapExceeded: false,
          ),
        ],
      );
      expect(
        _mapper.map(r).warnings.map((w) => w.code),
        contains(ContestImportWarning.rowsTruncated),
      );
    });

    test('a row without CompNo is reported and ignored', () {
      final d = _mapper.map(
        _tables({
          'Comps': [
            {'CompName': 'x', 'GSCompClass': 'F5J'},
          ],
        }),
      );
      expect(d.contests, isEmpty);
      expect(
        d.warnings.map((w) => w.code),
        contains(ContestImportWarning.compNumberMissing),
      );
    });

    test('pilotsUsedBy returns only the pilots of chosen importable comps', () {
      final d = _map('comps_reference.json');
      final used = d.pilotsUsedBy({22});
      expect(used.length, _comp(d, 22).participants.length);
      expect(d.pilotsUsedBy({20}), isEmpty, reason: 'skipped comp');
      expect(d.pilotsUsedBy({}), isEmpty);
      final both = d.pilotsUsedBy({21, 22});
      expect([
        for (final p in both) p.sourcePilotNo,
      ], [...both.map((p) => p.sourcePilotNo)]..sort());
      expect(
        both.length,
        lessThan(
          _comp(d, 21).participants.length +
              _comp(d, 22).participants.length +
              1,
        ),
      );
    });

    test('never throws on odd input', () {
      final r = _tables({
        'Comps': [
          {'CompNo': '1', 'CompName': 5, 'GSCompClass': 'F5J', 'CompDate': 5},
          {'CompNo': 2.0, 'GSCompClass': 'F5J', 'CompDate': '06/14/26'},
        ],
        'CompPilots': [
          {'CompNo': '2', 'PilotNo': 'x', 'Team': 'y', 'StartNo': 'z'},
        ],
        'Dur': [
          {'CompNo': 2, 'durTargetTime': 'nope', 'durRefHeight': true},
        ],
        'Pilots': [
          {'PilotNo': 'q'},
        ],
      });
      expect(() => _mapper.map(r), returnsNormally);
    });
  });
}

class _FakeMapper extends ClassMapper {
  const _FakeMapper();

  @override
  String get sourceClass => 'F3J';

  @override
  String get disciplineType => 'F3J';

  @override
  DisciplineMapping mapDiscipline(Map<String, Object?> configRow) =>
      DisciplineMapping(settings: const {'working_time': 1});
}
