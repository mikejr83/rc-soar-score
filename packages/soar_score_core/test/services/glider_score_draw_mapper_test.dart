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

Map<String, Object?> _score(
  int comp,
  int round,
  int group,
  int pilot,
  int seq, {
  int task = 1,
  int reflight = 0,
  bool scored = false,
}) => {
  'CompNo': comp,
  'TaskNo': task,
  'RoundNo': round,
  'GroupNo': group,
  'ReFlightNo': reflight,
  'PilotNo': pilot,
  'SeqNo': seq,
  'OriginalRoundNo': round,
  'Updated': scored ? 'True' : 'False',
};

/// A tiny file holding competition 1 (F5J) with [scores] and, unless set,
/// 6 lanes... no: [lanes] lanes and [groups] configured groups.
GliderScoreImportResult _file(
  List<Map<String, Object?>> scores, {
  int lanes = 0,
  int groups = 2,
  String compClass = 'F5J',
  bool withScores = true,
  bool rowCapExceeded = false,
}) {
  GliderScoreTable t(String name, List<Map<String, Object?>> rows) =>
      GliderScoreTable(
        name: name,
        rows: rows,
        rowCount: rows.length,
        rowCapExceeded: name == 'Scores' && rowCapExceeded,
      );
  return GliderScoreImportResult(
    id: Id.create(),
    sourceDbFile: 'test.mdb',
    tables: [
      t('Comps', [
        {'CompNo': 1, 'GSCompClass': compClass},
      ]),
      t('Dur', [
        {'CompNo': 1, 'durNbrOfLanes': lanes, 'durGroupsPerRound': groups},
      ]),
      if (withScores) t('Scores', scores),
    ],
  );
}

DrawImportTarget _target({
  Set<int> pilots = const {1, 2, 3, 4},
  bool stamped = true,
  String? stampedFingerprint = 'fp',
  bool hasMatrix = false,
  bool hasAcceptedScores = false,
}) => DrawImportTarget(
  sourceCompNo: 1,
  fileFingerprint: 'fp',
  stamped: stamped,
  stampedFingerprint: stampedFingerprint,
  hasMatrix: hasMatrix,
  hasAcceptedScores: hasAcceptedScores,
  participantPilotNos: pilots,
);

/// Two rounds, two groups of two pilots.
List<Map<String, Object?>> _simple() => [
  for (final r in [1, 2]) ...[
    _score(1, r, 1, 1, 1),
    _score(1, r, 1, 2, 2),
    _score(1, r, 2, 3, 1),
    _score(1, r, 2, 4, 2),
  ],
];

const mapper = GliderScoreDrawMapper();

/// The draw as compact JSON: rounds, groups, `pilot:lane` slots.
Map<String, Object?> _summary(DrawImportDraft d) => {
  'comp': d.sourceCompNo,
  'status': d.status.name,
  'laneCount': d.laneCount,
  'teamProtection': d.teamProtection,
  'revisions': [
    for (final r in d.revisions)
      {
        'number': r.revisionNumber,
        'task': r.taskNo,
        'rounds': '${r.firstRound}-${r.lastRound}',
        'groups': r.groupsPerRound,
        'draw': {
          for (final round in r.rounds)
            '${round.ordinal}': [
              for (final g in round.groups)
                [
                  for (final a in g.assignments)
                    '${a.sourcePilotNo}:${a.lane ?? '-'}/${a.seqNo}',
                ],
            ],
        },
      },
  ],
  'flights': d.flights.length,
  'scoredFlights': d.flights.where((f) => f.scored).length,
  'reflights': d.flights.where((f) => f.isReflight).length,
  'probablyUnflownRounds': d.probablyUnflownRounds,
  'warnings': [
    for (final w in d.warnings)
      [
        w.code,
        w.round,
        w.sourcePilotNo,
        w.detail,
      ].where((x) => x != null).join(' '),
  ],
};

DrawImportDraft _fixtureDraw(String file, int comp) {
  final result = _snapshot(file);
  final members = {
    for (final r
        in result.tables.firstWhere((t) => t.name == 'CompPilots').rows)
      if (r['CompNo'] == comp) (r['PilotNo']! as num).toInt(),
  };
  return mapper.mapCompetition(
    result,
    DrawImportTarget(
      sourceCompNo: comp,
      fileFingerprint: 'fp',
      stampedFingerprint: 'fp',
      participantPilotNos: members,
    ),
  );
}

void main() {
  group('golden drafts', () {
    final update = io.Platform.environment['UPDATE_GOLDEN'] == '1';
    for (final comp in [15, 21, 39]) {
      test('competition $comp matches its checked-in draft', () {
        final draft = _fixtureDraw('draws_reference.json', comp);
        expect(draft.isImportable, isTrue, reason: '${draft.reason}');
        final actual =
            '${const JsonEncoder.withIndent(' ').convert(_summary(draft))}\n';
        final file = File(
          'test/fixtures/gliderscore/expected/draw_comp_$comp.json',
        );
        if (update) {
          file.writeAsStringSync(actual);
        }
        expect(actual, file.readAsStringSync());
      });
    }
  });

  group('fixture scenarios', () {
    test('lane count 6: lane is the rank of SeqNo, a 7th pilot warns', () {
      final d = _fixtureDraw('draws_reference.json', 15);
      expect(d.laneCount, 6);
      final big = d.revisions
          .expand((r) => r.rounds)
          .expand((r) => r.groups)
          .where((g) => g.assignments.length == 7);
      expect(big, isNotEmpty);
      for (final g
          in d.revisions.expand((r) => r.rounds).expand((r) => r.groups)) {
        expect(
          [for (final a in g.assignments) a.lane],
          [for (var i = 1; i <= g.assignments.length; i++) i],
          reason: 'lanes close up to 1..n',
        );
      }
      expect(
        d.warnings.where(
          (w) => w.code == DrawImportWarning.laneBeyondLaneCount,
        ),
        isNotEmpty,
      );
    });

    test('lane count 0: no lanes, positions and SeqNo kept', () {
      final d = _fixtureDraw('draws_reference.json', 21);
      expect(d.laneCount, 0);
      final slots = d.revisions
          .expand((r) => r.rounds)
          .expand((r) => r.groups)
          .expand((g) => g.assignments);
      expect(slots.every((a) => a.lane == null), isTrue);
      expect(slots.any((a) => a.seqNo != a.position), isTrue, reason: 'gaps');
      expect(
        d.warnings.where(
          (w) => w.code == DrawImportWarning.laneBeyondLaneCount,
        ),
        isEmpty,
      );
    });

    test('observed groups win over the stale configured number', () {
      final d = _fixtureDraw('draws_reference.json', 26);
      expect(d.revisions, hasLength(1));
      expect(d.revisions.single.groupsPerRound, 2);
      final w = d.warnings.where(
        (w) => w.code == DrawImportWarning.groupsPerRoundDiffers,
      );
      expect(w, hasLength(7));
      expect(w.first.detail, 'configured 1, drawn 2');
    });

    test('unequal group sizes are imported as drawn with a warning', () {
      final d = _fixtureDraw('draws_reference.json', 26);
      expect(
        d.warnings.where((w) => w.code == DrawImportWarning.groupSizesDiffer),
        isNotEmpty,
      );
      final sizes = d.revisions.single.rounds.map(
        (r) => [for (final g in r.groups) g.assignments.length],
      );
      expect(sizes.any((s) => (s[0] - s[1]).abs() > 1), isTrue);
    });

    test('rounds drawn but not flown are listed as probably unflown', () {
      final d = _fixtureDraw('draws_reference.json', 28);
      expect(d.probablyUnflownRounds, [8, 9, 10]);
      // They are still part of the draw.
      expect(d.roundCount, 10);
    });

    test('a pure draw has every round probably unflown', () {
      final d = _fixtureDraw('draws_reference.json', 39);
      expect(d.probablyUnflownRounds, [for (var i = 1; i <= 10; i++) i]);
      expect(d.flights.where((f) => f.scored), isEmpty);
    });

    test('re-flights and unscored rows are kept for phase D, not drawn', () {
      final d = _fixtureDraw('draws_reference.json', 21);
      expect(d.flights.where((f) => f.isReflight), isNotEmpty);
      expect(
        _fixtureDraw(
          'draws_reference.json',
          15,
        ).flights.where((f) => !f.scored),
        isNotEmpty,
      );
      final firstFlights = d.flights.where((f) => !f.isReflight);
      expect(d.assignmentCount, firstFlights.length);
      final scored = d.flights.firstWhere(
        (f) => f.scored && f.rawScore != null,
      );
      expect(scored.time1Mins, isNotNull);
    });

    test('the draw is history: warning and fixed tag', () {
      final d = _fixtureDraw('draws_reference.json', 39);
      expect(
        d.warnings.map((w) => w.code),
        contains(DrawImportWarning.notReproducible),
      );
      expect(GliderScoreDrawMapper.algorithmVersion, 'import:gliderscore/1');
    });
  });

  group('structure', () {
    test('one revision when every round has the same group count', () {
      final d = mapper.mapCompetition(_file(_simple()), _target());
      expect(d.isImportable, isTrue);
      expect(d.revisions, hasLength(1));
      expect(d.revisions.single.firstRound, 1);
      expect(d.revisions.single.lastRound, 2);
      expect(d.assignmentCount, 8);
      expect(d.maxGroupsPerRound, 2);
      expect(d.pilots, {1, 2, 3, 4});
    });

    test('a changed group count starts a chained revision', () {
      final scores = [
        _score(1, 1, 1, 1, 1),
        _score(1, 1, 1, 2, 2),
        _score(1, 1, 2, 3, 1),
        _score(1, 1, 2, 4, 2),
        _score(1, 2, 1, 1, 1),
        _score(1, 2, 1, 2, 2),
        _score(1, 2, 1, 3, 3),
        _score(1, 2, 1, 4, 4),
        _score(1, 3, 1, 1, 1),
        _score(1, 3, 1, 2, 2),
        _score(1, 3, 1, 3, 3),
        _score(1, 3, 1, 4, 4),
      ];
      final d = mapper.mapCompetition(_file(scores), _target());
      expect([for (final r in d.revisions) r.groupsPerRound], [2, 1]);
      expect([for (final r in d.revisions) r.firstRound], [1, 2]);
      expect([for (final r in d.revisions) r.revisionNumber], [1, 2]);
    });

    test('an empty group inside 1..G still exists and warns', () {
      final scores = [
        _score(1, 1, 1, 1, 1),
        _score(1, 1, 1, 2, 2),
        _score(1, 1, 3, 3, 1),
        _score(1, 1, 3, 4, 2),
      ];
      final d = mapper.mapCompetition(_file(scores, groups: 3), _target());
      expect(d.revisions.single.rounds.single.groups, hasLength(3));
      expect(d.revisions.single.rounds.single.groups[1].assignments, isEmpty);
      expect(
        d.warnings.map((w) => w.code),
        contains(DrawImportWarning.emptyGroup),
      );
    });

    test('a duplicate or missing SeqNo is ordered by pilot number', () {
      final scores = [
        _score(1, 1, 1, 2, 1),
        _score(1, 1, 1, 1, 1),
        {..._score(1, 1, 2, 4, 1)}..remove('SeqNo'),
        _score(1, 1, 2, 3, 2),
      ];
      final d = mapper.mapCompetition(_file(scores, lanes: 4), _target());
      final groups = d.revisions.single.rounds.single.groups;
      expect([for (final a in groups[0].assignments) a.sourcePilotNo], [1, 2]);
      expect([for (final a in groups[1].assignments) a.sourcePilotNo], [3, 4]);
      expect(groups[1].assignments.last.seqNo, isNull);
      final codes = d.warnings.map((w) => w.code);
      expect(codes, contains(DrawImportWarning.seqNoDuplicate));
      expect(codes, contains(DrawImportWarning.seqNoMissing));
    });

    test('team protection is copied only when teams are on', () {
      GliderScoreImportResult withComp(Map<String, Object?> extra) {
        final base = _file(_simple());
        return GliderScoreImportResult(
          id: base.id,
          sourceDbFile: base.sourceDbFile,
          tables: [
            GliderScoreTable(
              name: 'Comps',
              rows: [
                {'CompNo': 1, 'GSCompClass': 'F5J', ...extra},
              ],
              rowCount: 1,
              rowCapExceeded: false,
            ),
            ...base.tables.skip(1),
          ],
        );
      }

      expect(
        mapper
            .mapCompetition(
              withComp({'UseTeams': 1, 'UseTeamProtection': 1}),
              _target(),
            )
            .teamProtection,
        isTrue,
      );
      expect(
        mapper
            .mapCompetition(withComp({'UseTeamProtection': 1}), _target())
            .teamProtection,
        isFalse,
      );
    });
  });

  group('refusals', () {
    void refuses(DrawImportDraft d, String reason, {String? detail}) {
      expect(d.status, DrawImportStatus.refused);
      expect(d.reason, reason);
      if (detail != null) {
        expect(d.reasonDetail, detail);
      }
      expect(d.revisions, isEmpty);
    }

    test('a contest without a phase B stamp', () {
      refuses(
        mapper.mapCompetition(_file(_simple()), _target(stamped: false)),
        DrawImportReason.notStamped,
      );
    });

    test('a file that differs from the stamp', () {
      refuses(
        mapper.mapCompetition(
          _file(_simple()),
          _target(stampedFingerprint: 'other'),
        ),
        DrawImportReason.fingerprintChanged,
      );
    });

    test('a contest that already has a matrix or accepted scores', () {
      refuses(
        mapper.mapCompetition(_file(_simple()), _target(hasMatrix: true)),
        DrawImportReason.alreadyDrawn,
      );
      refuses(
        mapper.mapCompetition(
          _file(_simple()),
          _target(hasAcceptedScores: true),
        ),
        DrawImportReason.hasAcceptedScores,
      );
    });

    test('a pilot with no participation', () {
      refuses(
        mapper.mapCompetition(_file(_simple()), _target(pilots: {1, 2, 3})),
        DrawImportReason.pilotWithoutParticipation,
        detail: '4',
      );
    });

    test('a moved credit (fixture)', () {
      final result = _snapshot('draws_edge_cases.json');
      final d = mapper.mapCompetition(
        result,
        const DrawImportTarget(
          sourceCompNo: 9201,
          fileFingerprint: 'fp',
          stampedFingerprint: 'fp',
          participantPilotNos: {2201, 2202, 2203, 2204},
        ),
      );
      refuses(d, DrawImportReason.creditMoved);
      expect(d.reasonDetail, contains('pilot 2201'));
    });

    test('overlapping and gapped task ranges', () {
      refuses(
        mapper.mapCompetition(
          _file([
            _score(1, 1, 1, 1, 1, task: 1),
            _score(1, 1, 1, 2, 2, task: 2),
          ]),
          _target(),
        ),
        DrawImportReason.taskRangesOverlap,
      );
      refuses(
        mapper.mapCompetition(
          _file([_score(1, 1, 1, 1, 1), _score(1, 3, 1, 1, 1)]),
          _target(),
        ),
        DrawImportReason.taskRangesGapped,
        detail: 'round 2 is missing',
      );
      refuses(
        mapper.mapCompetition(_file([_score(1, 2, 1, 1, 1)]), _target()),
        DrawImportReason.taskRangesGapped,
        detail: 'round 1 is missing',
      );
    });

    test('two first flights of a pilot in one round', () {
      refuses(
        mapper.mapCompetition(
          _file([_score(1, 1, 1, 1, 1), _score(1, 1, 2, 1, 1)]),
          _target(),
        ),
        DrawImportReason.duplicateFlight,
      );
    });

    test('a re-flight needs its first flight', () {
      refuses(
        mapper.mapCompetition(
          _file([_score(1, 1, 1, 1, 1), _score(1, 1, 1, 2, 2, reflight: 1)]),
          _target(),
        ),
        DrawImportReason.reflightWithoutOriginal,
      );
    });

    test('missing tables, rows and classes', () {
      refuses(
        mapper.mapCompetition(_file(const [], withScores: false), _target()),
        DrawImportReason.scoresUnavailable,
      );
      refuses(
        mapper.mapCompetition(
          _file(_simple(), rowCapExceeded: true),
          _target(),
        ),
        DrawImportReason.scoresUnavailable,
      );
      refuses(
        mapper.mapCompetition(_file(const []), _target()),
        DrawImportReason.noDraw,
      );
      refuses(
        mapper.mapCompetition(_file(_simple(), compClass: 'F3J'), _target()),
        DrawImportReason.classNotSupported,
        detail: 'F3J',
      );
      refuses(
        mapper.mapCompetition(
          _file(_simple()),
          const DrawImportTarget(
            sourceCompNo: 7,
            fileFingerprint: 'fp',
            stampedFingerprint: 'fp',
          ),
        ),
        DrawImportReason.competitionMissing,
      );
    });

    test('odd rows never throw', () {
      for (final row in <Map<String, Object?>>[
        {},
        {'CompNo': 1},
        {'CompNo': 1, 'TaskNo': 'x', 'RoundNo': 1, 'GroupNo': 1, 'PilotNo': 1},
        {'CompNo': 1, 'TaskNo': 1, 'RoundNo': 0, 'GroupNo': 1, 'PilotNo': 1},
        {
          'CompNo': '1',
          'TaskNo': '1',
          'RoundNo': '1',
          'GroupNo': '1',
          'PilotNo': '1',
        },
        {'CompNo': 1, 'TaskNo': 1, 'RoundNo': 1, 'GroupNo': -3, 'PilotNo': 1},
      ]) {
        final d = mapper.mapCompetition(_file([row]), _target());
        expect([
          DrawImportStatus.importable,
          DrawImportStatus.refused,
        ], contains(d.status));
      }
    });

    test('mapAll returns one draft per target in competition order', () {
      final result = _file(_simple());
      final drafts = mapper.map(result, [
        _target(),
        const DrawImportTarget(
          sourceCompNo: 0,
          fileFingerprint: 'fp',
          stamped: false,
        ),
      ]);
      expect([for (final d in drafts) d.sourceCompNo], [0, 1]);
      expect(drafts.first.reason, DrawImportReason.notStamped);
      expect(drafts.last.isImportable, isTrue);
    });
  });
}
