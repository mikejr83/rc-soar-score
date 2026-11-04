// Builds the anonymised GliderScore pilot fixtures used by the pilot import
// tests (#697) from a real GliderScore database.
//
// The real file holds names and email addresses, so nothing from it is
// committed: this script replaces every identifying value with a stable fake
// and refuses to write anything that still contains an original text value.
// Only an allowlist of columns is carried over; every other column is dropped.
//
// Steps (any machine with mdbtools; on Windows use the bundled
// tools/gs_importer/bin/x86/mdb-json.exe):
//
//   mdb-json GliderScoreData.mdb Pilots > pilots.jsonl
//   dart scripts/scrub_gliderscore_pilots.dart pilots.jsonl \
//       packages/soar_score_core/test/fixtures/gliderscore
//
// Output (all `gs-import/v1` snapshots with one `Pilots` table, rows shaped
// like mdb-json writes them, so columns that are null are absent):
//
//   pilots_reference.json     every pilot of the input, scrubbed
//   pilots_edge_cases.json    hand-built rows for the mapper and matcher rules
//   pilots_old_columns.json   a few rows with the older GliderScore column set
//   pilots_extra_columns.json rows carrying columns the importer does not know
//
// Competition fixtures (#744, phase B): pass a directory holding the
// mdb-json exports of Comps, CompPilots, Roles, Dur and DBParams as a third
// argument and the script also writes
//
//   for t in Comps CompPilots Roles Dur DBParams; do
//     mdb-json GliderScoreData.mdb $t > comps/$t.jsonl; done
//   dart scripts/scrub_gliderscore_pilots.dart pilots.jsonl <out> comps
//
//   comps_reference.json      real comps 22, 39, 21 (F5J), 20 (F3J, skipped)
//                             and 40 (F5L, skipped), with their pilots
//   comps_edge_cases.json     hand-built comps: teams, retired pilots, every
//                             role, five drops, no config row, unknown class
//   comps_missing_columns.json  comp 22 reduced to its required columns
//   comps_integrity_cases.json  hand-built broken references: a duplicated
//                             CompNo, a duplicated (CompNo, PilotNo) and a
//                             participant with no Pilots row
//
// Draw fixtures (#768, phase C): when the directory also holds Scores.jsonl
// (`mdb-json GliderScoreData.mdb Scores > comps/Scores.jsonl`) the script
// also writes
//
//   draws_reference.json      real comps 15, 21, 26, 28 and 39 with their
//                             Scores rows (the drawn flights, scored or not)
//   draws_edge_cases.json     hand-built comps for the draw refusals
//
// Scores holds numbers only (plus the True/False `Updated` flag); every
// value's shape is checked and the script aborts on anything else.
//
// Score fixtures (#768, phase D): when the directory also holds
// LndgNames.jsonl and LndgPoints.jsonl (same `mdb-json` call) the script
// also writes
//
//   scores_reference.json     real comps 35, 29, 16, 19 and 10 with their
//                             Scores rows and landing tables (restart option
//                             1, 2 and NULL, restart zeros, a floored zero,
//                             all-zero flights, partly flown rounds, a retired
//                             pilot, unflown trailing rounds, a competition
//                             with no CompID and a non-default landing table)
//   scores_edge_cases.json    hand-built comps: a partial landing match, a
//                             reconstructed landing table, a retired pilot
//                             with no scores, a subset re-flight and
//                             overlapping task ranges
//   reimport_v1.json          comp 19 early: rounds 1 and 2 scored
//   reimport_v2.json          comp 19 later: round 3 scored, one score
//                             changed, one pilot added
//   reimport_v1_copy.json     the same content as v1 from another file
//
// Competition and venue names, comp ids and model names become fakes; the
// rest of a comp row is codes and flags and is kept (allowlist, as for
// pilots).
//
// Deterministic: same input, same output. Needs only the Dart SDK.

import 'dart:convert';
import 'dart:io';

/// Words that appear in GliderScore's own lookup values.
const _lookupWords = <String>{'pilot', 'back', 'helper'};

const _snapshotId = '00000000-0000-7000-8000-000000000001';
const _emailDomain = 'example.test';

const _firstNames = <String>[
  'Alex',
  'Blair',
  'Casey',
  'Dana',
  'Eden',
  'Frankie',
  'Glenn',
  'Harper',
  'Indigo',
  'Jordan',
  'Kai',
  'Lane',
  'Morgan',
  'Nico',
  'Oakley',
  'Parker',
  'Quinn',
  'Riley',
  'Sage',
  'Taylor',
  'Uma',
  'Val',
  'Wren',
  'Yael',
  'Zion',
];

const _lastNames = <String>[
  'Ashdown',
  'Birchall',
  'Candlewick',
  'Dunmore',
  'Eastwick',
  'Fairweather',
  'Gladstone',
  'Hawthorne',
  'Ironside',
  'Jessup',
  'Kingsley',
  'Larkspur',
  'Marlowe',
  'Northcott',
  'Oakenfold',
  'Pemberton',
  'Quillfeather',
  'Ravenscroft',
  'Sandford',
  'Thistlewood',
  'Underhill',
  'Valence',
  'Whitlock',
  'Yarrow',
  'Zephyr',
];

void main(List<String> args) {
  if (args.length != 2 && args.length != 3) {
    stderr.writeln(
      'usage: dart scripts/scrub_gliderscore_pilots.dart '
      '<pilots.jsonl> <output dir> [<comps jsonl dir>]',
    );
    exit(64);
  }
  final input = File(args[0]);
  final outDir = Directory(args[1]);
  if (!input.existsSync()) {
    stderr.writeln('input not found: ${input.path}');
    exit(66);
  }

  final original = <Map<String, Object?>>[
    for (final line in input.readAsLinesSync())
      if (line.trim().isNotEmpty)
        (jsonDecode(line) as Map<String, dynamic>).cast<String, Object?>(),
  ];
  final scrubbed = [for (final row in original) _scrub(row)];
  final realPilots = [
    for (final row in scrubbed)
      if (!(row['LastName']! as String).startsWith('ZZ')) row,
  ];

  final files = <String, List<Map<String, Object?>>>{
    'pilots_reference.json': scrubbed,
    'pilots_edge_cases.json': _edgeCases(),
    'pilots_old_columns.json': [
      for (final row in realPilots.take(12))
        {
          for (final key in const [
            'PilotNo',
            'Country',
            'FAINumber',
            'UsualClass',
            'Filter',
            'FirstName',
            'LastName',
          ])
            if (row.containsKey(key)) key: row[key],
        },
    ],
    'pilots_extra_columns.json': [
      for (final row in realPilots.take(5))
        {...row, 'FutureColumn': 'x', 'AnotherNewThing': 7},
    ],
  };

  final rendered = {
    for (final entry in files.entries) entry.key: _snapshot(entry.value),
  };
  if (args.length == 3) {
    rendered.addAll(_competitionFixtures(Directory(args[2]), scrubbed));
  }
  _refuseLeaks(original, rendered.values);

  outDir.createSync(recursive: true);
  for (final entry in rendered.entries) {
    File('${outDir.path}/${entry.key}').writeAsStringSync(entry.value);
    stdout.writeln('wrote ${entry.key}');
  }
}

/// Columns kept as they are: codes and flags that identify nobody. Anything
/// not named here or in [_replaced] is dropped, so an unexpected column (a
/// phone number, an address) can never reach a fixture.
const _keptVerbatim = <String>{
  'PilotNo',
  'Country',
  'State',
  'UsualClass',
  'Filter',
};

/// Columns replaced with fakes (or dropped when blank).
const _replaced = <String>{
  'FirstName',
  'LastName',
  'Email',
  'FAINumber',
  'FAI_ID',
  'OtherRegistration',
  'Club',
  'Town',
};

Map<String, Object?> _scrub(Map<String, Object?> row) {
  final no = (row['PilotNo'] as num).toInt();
  final isTestUser = ((row['LastName'] as String?) ?? '')
      .trim()
      .toUpperCase()
      .startsWith('ZZ');
  final last =
      _lastNames[no % _lastNames.length] +
      (no ~/ _lastNames.length == 0 ? '' : '${no ~/ _lastNames.length}');
  // "0", blank and whitespace are GliderScore's "none"; a real number becomes
  // a fake that is stable per pilot.
  Object? number(Object? value, String prefix) =>
      _hasText(value) && !RegExp(r'^\s*0+\s*$').hasMatch(value! as String)
      ? '$prefix$no'
      : value;
  return {
    for (final entry in row.entries)
      if (_keptVerbatim.contains(entry.key) || _replaced.contains(entry.key))
        entry.key: switch (entry.key) {
          'FirstName' => _firstNames[(no * 7) % _firstNames.length],
          'LastName' => isTestUser ? 'ZZ$last' : last,
          'Email' => _hasText(entry.value) ? 'fixture$no@$_emailDomain' : null,
          'FAINumber' || 'FAI_ID' => number(entry.value, 'FAI-'),
          'OtherRegistration' => number(entry.value, 'REG-'),
          'Club' => _hasText(entry.value) ? 'Example Club ${no % 5}' : null,
          'Town' => _hasText(entry.value) ? 'Exampleton' : null,
          _ => entry.value,
        },
  }..removeWhere((_, value) => value == null);
}

bool _hasText(Object? value) => value is String && value.trim().isNotEmpty;

/// Hand-built rows for rules the real file does not exercise.
List<Map<String, Object?>> _edgeCases() => <Map<String, Object?>>[
  // Two different pilots with the same name and no stronger key.
  {'PilotNo': 1001, 'FirstName': 'Sam', 'LastName': 'Twin', 'Country': 'USA'},
  {'PilotNo': 1002, 'FirstName': 'Sam', 'LastName': 'Twin', 'Country': 'USA'},
  // Same email on two entries (one with different case and padding).
  {
    'PilotNo': 1003,
    'FirstName': 'Ellis',
    'LastName': 'Shared',
    'Email': 'shared@$_emailDomain',
  },
  {
    'PilotNo': 1004,
    'FirstName': 'Ellis',
    'LastName': 'Sharedname',
    'Email': '  Shared@${_emailDomain.toUpperCase()} ',
  },
  // A real FAI number and a national registration.
  {
    'PilotNo': 1005,
    'FirstName': 'Fay',
    'LastName': 'Registered',
    'FAINumber': 'FAI12345',
    'OtherRegistration': 'NAT-0042',
    'FAI_ID': 'FAI12345',
    'Country': 'AUS',
  },
  // FAI_ID that differs from FAINumber.
  {
    'PilotNo': 1006,
    'FirstName': 'Gil',
    'LastName': 'Differs',
    'FAINumber': 'FAI777',
    'FAI_ID': 'FAI888',
  },
  // Blank and placeholder values.
  {
    'PilotNo': 1007,
    'FirstName': 'Hal',
    'LastName': 'Blanks',
    'FAINumber': '0',
    'OtherRegistration': '0',
    'FAI_ID': ' ',
    'Email': '',
    'Country': '',
    'State': ' ',
  },
  // Test-user prefixes: lower case, padded, and a name that merely contains zz.
  {'PilotNo': 1008, 'FirstName': 'Ida', 'LastName': 'zzLower'},
  {'PilotNo': 1009, 'FirstName': 'Jo', 'LastName': '  ZZPadded '},
  {'PilotNo': 1010, 'FirstName': 'Kit', 'LastName': 'Pizzazz'},
  // Missing or blank names.
  {'PilotNo': 1011, 'LastName': 'NoFirst'},
  {'PilotNo': 1012, 'FirstName': 'NoLast'},
  {'PilotNo': 1013, 'FirstName': ' ', 'LastName': ' '},
  // Country codes: IOC (differs from ISO), unknown, lower case, ISO-looking.
  {'PilotNo': 1014, 'FirstName': 'Lee', 'LastName': 'Ioc', 'Country': 'GER'},
  {
    'PilotNo': 1015,
    'FirstName': 'Mack',
    'LastName': 'Unknown',
    'Country': 'XXX',
  },
  {'PilotNo': 1016, 'FirstName': 'Ned', 'LastName': 'Lower', 'Country': 'usa'},
  // Whitespace and accents in names, and club/town style columns.
  {
    'PilotNo': 1017,
    'FirstName': '  Zoë ',
    'LastName': 'Accent ',
    'Club': 'Example Soaring Club',
    'Town': 'Exampleton',
    'State': 'ZZ',
  },
  // Columns that never map.
  {
    'PilotNo': 1018,
    'FirstName': 'Ola',
    'LastName': 'Dropped',
    'UsualClass': 'F5J',
    'UsualModel': 'Example Model',
    'Street': '1 Example Street',
    'PostCode': '00000',
    'PrivatePhone': '000',
    'WorkPhone': '000',
    'Filter': 'Y',
  },
];

String _snapshot(List<Map<String, Object?>> rows) {
  final snapshot = <String, Object?>{
    'schema': 'gs-import/v1',
    'id': _snapshotId,
    'sourceDbFile': 'GliderScoreData.mdb',
    'tables': [
      {
        'name': 'Pilots',
        'rowCount': rows.length,
        'rowCapExceeded': false,
        'rows': rows,
      },
    ],
  };
  return '${const JsonEncoder.withIndent('  ').convert(snapshot)}\n';
}

/// Fails (writing nothing) if any original name or email survives.
void _refuseLeaks(
  List<Map<String, Object?>> original,
  Iterable<String> outputs,
) {
  final secrets = <String>{};
  for (final row in original) {
    for (final entry in row.entries) {
      if (_keptVerbatim.contains(entry.key)) {
        continue;
      }
      final value = entry.value;
      if (value is String && value.trim().length >= 4) {
        secrets.add(value.trim().toLowerCase());
      }
    }
  }
  final text = outputs.join('\n').toLowerCase();
  final leaked = [
    for (final secret in secrets)
      // Words of the Roles lookup table and the draw-option string
      // ("Pilot", "Back2Back") that also happen to be test-pilot names.
      if (!_lookupWords.contains(secret) &&
          RegExp('(^|[^a-z])${RegExp.escape(secret)}(\$|[^a-z])')
              .hasMatch(text))
        secret,
  ];
  if (leaked.isNotEmpty) {
    stderr.writeln(
      'refusing to write: ${leaked.length} original value(s) would appear in '
      'the fixtures (${leaked.take(5).join(', ')}). Change the fake pools or '
      'the hand-built rows.',
    );
    exit(1);
  }
}

// ---------------------------------------------------------------------------
// Competition fixtures (#744)

const _compsKept = <String>{
  'CompNo', 'CompDate', 'Drop1AtRound', 'Drop2AtRound', 'Drop3AtRound',
  'Drop4AtRound', 'Drop5AtRound', 'UseTeams', 'UseTeamProtection',
  'UseClasses', 'UseModels', 'UsePilotNumbering', 'Enforce20KHz',
  'GroupScoreDecimals', 'ScoresLocked', 'NbrForTeamScore', 'printCountry',
  'RoundOrTruncate', 'GroupScoreOption', 'printRegistration', 'UseRoles',
  'DropScoreOption', 'AssignHelpers', 'DrawMode', 'GSCompClass',
  'PrelimCompNo', 'F3QDrop6to10', 'IsPublic', 'UseRegistration',
  'UseRegistrationIdx', //
};

const _compPilotsKept = <String>{
  'CompNo', 'PilotNo', 'PilotClass', 'Team', 'DrawFreq', 'Retired', 'StartNo',
  'Role', 'IsPilot', 'OmitFromTeamScore', //
};

/// Every table that is read from the real file and carried over unchanged
/// apart from the allowlist: the Dur config rows hold only numbers and the
/// draw-option query string, which names nobody.
const _durKept = <String>{
  'CompNo', 'durTargetTime', 'durDecimalsForTiming', 'durLndg',
  'durNumberOfTimekeepers', 'durGroupsPerRound', 'durPilotsMax',
  'durDrawLocked', 'durFlightPenalty', 'durNbrOfLanes', 'durRefHeight',
  'durPenaltyUpToRefHeight', 'durPenaltyOverRefHeight', 'durAllowBackToBack',
  'DurPointsPerSecond', 'durPilotsMin', 'F5JMotorRestartOption', //
};

/// Every column of `Scores` the importer knows. All are numbers except
/// `Updated`, a True/False flag. Nothing else is carried over.
const _scoresKept = <String>{
  'CompNo', 'TaskNo', 'RoundNo', 'GroupNo', 'ReFlightNo', 'PilotNo', 'SeqNo',
  'DrawFreq', 'Time1Mins', 'Time1Secs', 'Time2Mins', 'Time2Secs',
  'FlightScoreDeduction', 'Landing', 'RawScore', 'NormalisedScore', 'Penalty',
  'OriginalRoundNo', 'ScoresChecked', 'Updated', 'LandingOver75m', 'Helper',
  'Laps', 'F5JMotorReStarted', //
};

/// Keeps the allowlisted columns of one `Scores` row after checking each
/// value's shape: a number, or True/False for `Updated`. A text value in
/// any other column would be personal data, so the script stops.
Map<String, Object?> _validScores(Map<String, Object?> row) {
  final out = <String, Object?>{};
  for (final e in row.entries) {
    if (!_scoresKept.contains(e.key) || e.value == null) {
      continue;
    }
    final v = e.value;
    final ok = e.key == 'Updated' ? v == 'True' || v == 'False' : v is num;
    if (!ok) {
      _abort('Scores column ${e.key} has an unexpected value shape');
    }
    out[e.key] = v;
  }
  return out;
}

List<Map<String, Object?>> _readJsonl(File file) => [
  for (final line in file.readAsLinesSync())
    if (line.trim().isNotEmpty)
      (jsonDecode(line) as Map<String, dynamic>).cast<String, Object?>(),
];

Map<String, String> _competitionFixtures(
  Directory dir,
  List<Map<String, Object?>> scrubbedPilots,
) {
  List<Map<String, Object?>> table(String name) =>
      _readJsonl(File('${dir.path}/$name.jsonl'));
  final comps = table('Comps');
  final compPilots = table('CompPilots');
  final dur = [for (final r in table('Dur')) _validDur(r)];
  // Roles and DBParams are never copied: the fixed lookup rows are emitted
  // after the file's rows have been checked against them.
  final roles = _validatedRoles(table('Roles'));
  final dbParams = _validatedDbParams(table('DBParams'));
  _reportDroppedColumns({
    'Comps': (comps, {..._compsKept, 'CompID', 'CompName', 'CompVenue'}),
    'CompPilots': (compPilots, {..._compPilotsKept, 'Model', 'ModelData'}),
    'Dur': (dur, _durKept),
  });

  // Model names are fakes, stable per original name.
  final models = <String, String>{};
  String model(String original) => models.putIfAbsent(
    original.trim().toLowerCase(),
    () => 'Example Model ${models.length + 1}',
  );

  Map<String, Object?> compRow(Map<String, Object?> row) {
    final no = (row['CompNo']! as num).toInt();
    return {
      for (final e in row.entries)
        if (_compsKept.contains(e.key) && e.value != null) e.key: e.value,
      // Older files carry no CompID; the fixture keeps that difference.
      if (_hasText(row['CompID'])) 'CompID': 'FIXTURE$no',
      'CompName': 'Fixture Open $no',
      'CompVenue': 'Example Field',
    };
  }

  Map<String, Object?> compPilotRow(Map<String, Object?> row) => {
    for (final e in row.entries)
      if (_compPilotsKept.contains(e.key) && e.value != null) e.key: e.value,
    if (_hasText(row['Model'])) 'Model': model(row['Model']! as String),
    if (row['ModelData'] is String &&
        RegExp(r'^-?\d+$').hasMatch(row['ModelData']! as String))
      'ModelData': row['ModelData'],
  };

  Map<String, Object?> durRow(Map<String, Object?> row) => {
    for (final e in row.entries)
      if (_durKept.contains(e.key) && e.value != null) e.key: e.value,
  };

  final pilotsByNo = {
    for (final p in scrubbedPilots) (p['PilotNo']! as num).toInt(): p,
  };

  /// Builds one snapshot holding the given comps with everything they use.
  String snapshot(
    Iterable<int> compNos, {
    bool withRoles = true,
    bool withDbParams = true,
    Map<String, List<Map<String, Object?>>> extraTables = const {},
    String id = _snapshotId,
    String sourceDbFile = 'GliderScoreData.mdb',
    List<Map<String, Object?>> extraCompPilots = const [],
  }) {
    final nos = compNos.toSet();
    bool inScope(Map<String, Object?> r) => nos.contains(r['CompNo']);
    final cp = [
      for (final r in compPilots)
        if (inScope(r)) compPilotRow(r),
      ...extraCompPilots,
    ];
    final pilotNos = {for (final r in cp) (r['PilotNo']! as num).toInt()};
    return _snapshotTables(
      {
        'Comps': [
          for (final r in comps)
            if (inScope(r)) compRow(r),
        ],
        'CompPilots': cp,
        'Pilots': [
          for (final no in pilotNos.toList()..sort())
            if (pilotsByNo[no] != null) pilotsByNo[no]!,
        ],
        if (withRoles) 'Roles': roles,
        'Dur': [
          for (final r in dur)
            if (inScope(r)) durRow(r),
        ],
        if (withDbParams) 'DBParams': dbParams,
        ...extraTables,
      },
      id: id,
      sourceDbFile: sourceDbFile,
    );
  }

  // Draw fixtures: needs Scores.jsonl next to the other exports.
  Map<String, String> scoresFixtures() {
    final file = File('${dir.path}/Scores.jsonl');
    if (!file.existsSync()) {
      return const {};
    }
    final scores = [for (final r in _readJsonl(file)) _validScores(r)];
    _reportDroppedColumns({'Scores': (scores, _scoresKept)});
    const nos = [15, 21, 26, 28, 39];
    final base = jsonDecode(snapshot(nos)) as Map<String, Object?>;
    final tables = [
      for (final t in (base['tables']! as List<Object?>))
        {...(t! as Map<String, Object?>)},
    ];
    final rows = [
      for (final r in scores)
        if (nos.contains(r['CompNo'])) r,
    ];
    tables.add({
      'name': 'Scores',
      'rowCount': rows.length,
      'rowCapExceeded': false,
      'rows': rows,
    });
    return {
      'draws_reference.json': _snapshotJson({...base, 'tables': tables}),
      'draws_edge_cases.json': _drawEdgeCases(),
    };
  }

  // Score fixtures (phase D): needs Scores, LndgNames and LndgPoints.
  Map<String, String> scoreFixtures() {
    final scoresFile = File('${dir.path}/Scores.jsonl');
    final namesFile = File('${dir.path}/LndgNames.jsonl');
    final pointsFile = File('${dir.path}/LndgPoints.jsonl');
    if (!scoresFile.existsSync() ||
        !namesFile.existsSync() ||
        !pointsFile.existsSync()) {
      return const {};
    }
    final scores = [for (final r in _readJsonl(scoresFile)) _validScores(r)];
    final names = _validLndgNames(_readJsonl(namesFile));
    final points = _validLndgPoints(_readJsonl(pointsFile));
    _reportDroppedColumns({'Scores': (scores, _scoresKept)});

    List<Map<String, Object?>> scoresOf(Iterable<int> nos) => [
      for (final r in scores)
        if (nos.contains(r['CompNo'])) r,
    ];
    Map<String, List<Map<String, Object?>>> landing(Iterable<int> nos) {
      final used = {
        for (final d in dur)
          if (nos.contains(d['CompNo']) && d['durLndg'] != null)
            (d['durLndg']! as num).toInt(),
      };
      return {
        'LndgNames': [
          for (final r in names)
            if (used.contains(r['LndgNo'])) r,
        ],
        'LndgPoints': [
          for (final r in points)
            if (used.contains(r['LndgNo'])) r,
        ],
      };
    }

    const refNos = [35, 29, 16, 19, 10];
    // Comp 19 early (round 3 only drawn), later (everything scored, one
    // landing changed and one pilot added) and an identical copy of the
    // early file.
    final comp19 = scoresOf(const [19]);
    final early = [
      for (final r in comp19)
        if (r['RoundNo'] == 3)
          {
            for (final e in r.entries)
              e.key: switch (e.key) {
                'Updated' => 'False',
                'Time1Mins' ||
                'Time1Secs' ||
                'Time2Mins' ||
                'Time2Secs' ||
                'FlightScoreDeduction' ||
                'Landing' ||
                'RawScore' ||
                'NormalisedScore' ||
                'Penalty' ||
                'Laps' => 0,
                _ => e.value,
              },
          }
        else
          r,
    ];
    // Round 1, pilot 109: the landing was corrected from 50 to 45, which
    // lowers the raw score by 5 (group scores are not recomputed).
    final later = [
      for (final r in comp19)
        if (r['RoundNo'] == 1 && r['PilotNo'] == 109)
          {...r, 'Landing': 45, 'RawScore': (r['RawScore']! as num) - 5}
        else
          r,
    ];
    final inComp19 = {
      for (final r in compPilots)
        if (r['CompNo'] == 19) (r['PilotNo']! as num).toInt(),
    };
    final addedPilot = (pilotsByNo.keys.toList()..sort()).firstWhere(
      (no) => !inComp19.contains(no) && (pilotsByNo[no]!['IsPilot'] ?? 1) != 0,
    );
    final added = {
      ...compPilotRow(compPilots.firstWhere((r) => r['CompNo'] == 19)),
      'PilotNo': addedPilot,
    };
    final extra19 = landing(const [19]);

    return {
      'scores_reference.json': snapshot(
        refNos,
        extraTables: {...landing(refNos), 'Scores': scoresOf(refNos)},
      ),
      'scores_edge_cases.json': _scoreEdgeCases(),
      'reimport_v1.json': snapshot(
        const [19],
        extraTables: {...extra19, 'Scores': early},
        id: '00000000-0000-7000-8000-000000000011',
        sourceDbFile: 'GliderScoreData.mdb',
      ),
      'reimport_v2.json': snapshot(
        const [19],
        extraTables: {...extra19, 'Scores': later},
        extraCompPilots: [added],
        id: '00000000-0000-7000-8000-000000000012',
        sourceDbFile: 'GliderScoreData.mdb',
      ),
      'reimport_v1_copy.json': snapshot(
        const [19],
        extraTables: {...extra19, 'Scores': early},
        id: '00000000-0000-7000-8000-000000000013',
        sourceDbFile: 'GliderScoreDataCopy.mdb',
      ),
    };
  }

  // Comp 22 reduced to the columns the mapper cannot do without.
  String missingColumns() {
    final c = comps.firstWhere((r) => r['CompNo'] == 22);
    final cp = [
      for (final r in compPilots)
        if (r['CompNo'] == 22) r,
    ];
    final pilotNos = {for (final r in cp) (r['PilotNo']! as num).toInt()};
    final d = dur.firstWhere((r) => r['CompNo'] == 22);
    return _snapshotTables({
      'Comps': [
        {
          'CompNo': 22,
          'CompName': 'Fixture Open 22',
          'GSCompClass': c['GSCompClass'],
          'CompDate': c['CompDate'],
        },
      ],
      'CompPilots': [
        for (final r in cp) {'CompNo': 22, 'PilotNo': r['PilotNo']},
      ],
      'Pilots': [
        for (final no in pilotNos.toList()..sort())
          if (pilotsByNo[no] != null)
            {
              'PilotNo': no,
              'FirstName': pilotsByNo[no]!['FirstName'],
              'LastName': pilotsByNo[no]!['LastName'],
            },
      ],
      'Dur': [
        {'CompNo': 22, 'durTargetTime': d['durTargetTime']},
      ],
    });
  }

  final out = <String, String>{
    'comps_reference.json': snapshot(const [22, 39, 21, 20, 40]),
    ...scoresFixtures(),
    ...scoreFixtures(),
    'comps_edge_cases.json': _competitionEdgeCases(),
    'comps_integrity_cases.json': _competitionIntegrityCases(),
    'comps_missing_columns.json': missingColumns(),
  };

  // Refuse to write when an original competition, venue or model name (or
  // any other original text outside the kept codes) shows up in the output.
  final secrets = <String>{};
  void collect(List<Map<String, Object?>> rows, Set<String> kept) {
    for (final row in rows) {
      for (final e in row.entries) {
        final v = e.value;
        if (!kept.contains(e.key) && v is String && v.trim().length >= 4) {
          secrets.add(v.trim().toLowerCase());
        }
      }
    }
  }

  collect(comps, _compsKept);
  collect(compPilots, _compPilotsKept);
  // Every other table read is scanned too; only the validated lookup values
  // (Roles, DBVersion, the Dur draw-option string) are excused, by shape.
  collect(table('Roles'), const {});
  collect([
    for (final r in table('DBParams'))
      if (r['Property'] != 'DBVersion') r,
  ], const {});
  collect(table('Dur'), _durKept);
  final text = out.values
      .join('\n')
      .toLowerCase()
      .replaceAll('@$_emailDomain', '');
  final leaked = [
    for (final secret in secrets)
      // Fixture ids and fake names are built from these words on purpose.
      if (!secret.startsWith('fixture') &&
          !secret.startsWith('example') &&
          !_validatedLookupValues.contains(secret) &&
          RegExp('(^|[^a-z])${RegExp.escape(secret)}(\$|[^a-z])')
              .hasMatch(text))
        secret,
  ];
  if (leaked.isNotEmpty) {
    stderr.writeln(
      'refusing to write: ${leaked.length} original competition value(s) '
      'would appear in the fixtures: ${leaked.take(5).join(', ')}',
    );
    exit(1);
  }
  return out;
}

String _snapshotTables(
  Map<String, List<Map<String, Object?>>> tables, {
  String id = _snapshotId,
  String sourceDbFile = 'GliderScoreData.mdb',
}) {
  return _snapshotJson({
    'schema': 'gs-import/v1',
    'id': id,
    'sourceDbFile': sourceDbFile,
    'tables': [
      for (final e in tables.entries)
        {
          'name': e.key,
          'rowCount': e.value.length,
          'rowCapExceeded': false,
          'rows': e.value,
        },
    ],
  });
}

/// Renders a snapshot with two-space indentation, except that the rows of
/// the `Scores` table are one line each: a draw is hundreds of rows and the
/// fixtures stay small and reviewable that way.
String _snapshotJson(Map<String, Object?> snapshot) {
  const indent = JsonEncoder.withIndent('  ');
  final tables = (snapshot['tables']! as List<Object?>)
      .cast<Map<String, Object?>>();
  final compact = <String, List<Object?>>{};
  final shaped = <Map<String, Object?>>[];
  for (final table in tables) {
    if (table['name'] == 'Scores') {
      final rows = (table['rows']! as List<Object?>);
      compact[table['name']! as String] = rows;
      shaped.add({...table, 'rows': <Object?>[]});
    } else {
      shaped.add(table);
    }
  }
  var text = indent.convert({...snapshot, 'tables': shaped});
  for (final e in compact.entries) {
    final body = e.value.isEmpty
        ? '[]'
        : '[\n${[for (final r in e.value) '          ${jsonEncode(r)}'].join(',\n')}\n        ]';
    final marker = '"name": "${e.key}",';
    final start = text.indexOf(marker);
    final rowsAt = text.indexOf('"rows": []', start);
    text = text.replaceRange(
      rowsAt,
      rowsAt + '"rows": []'.length,
      '"rows": $body',
    );
  }
  return '$text\n';
}

/// Hand-built competitions for rules the real file does not exercise (it has
/// no F5J comp with teams, and every participant is a plain pilot).
String _competitionEdgeCases() {
  Map<String, Object?> comp(
    int no, {
    String cls = 'F5J',
    Map<String, Object?> extra = const {},
  }) => {
    'CompNo': no,
    'CompDate': '06/14/26 00:00:00',
    'Drop1AtRound': 99,
    'Drop2AtRound': 99,
    'Drop3AtRound': 99,
    'Drop4AtRound': 99,
    'Drop5AtRound': 99,
    'UseTeams': 0,
    'UseTeamProtection': 0,
    'UseClasses': 0,
    'UseModels': 0,
    'UsePilotNumbering': 0,
    'Enforce20KHz': 1,
    'GroupScoreDecimals': 2,
    'ScoresLocked': 0,
    'NbrForTeamScore': 3,
    'printCountry': 0,
    'RoundOrTruncate': 1,
    'GroupScoreOption': 1,
    'printRegistration': 0,
    'UseRoles': 0,
    'DropScoreOption': 0,
    'CompID': 'FIXTURE$no',
    'AssignHelpers': 0,
    'CompName': 'Fixture Open $no',
    'CompVenue': 'Example Field',
    'DrawMode': 0,
    'GSCompClass': cls,
    'PrelimCompNo': -1,
    'IsPublic': 0,
    'UseRegistration': 0,
    'UseRegistrationIdx': 0,
    ...extra,
  };
  Map<String, Object?> dur(int no, {Map<String, Object?> extra = const {}}) => {
    'CompNo': no,
    'durTargetTime': 600,
    'durDecimalsForTiming': 0,
    'durLndg': 9,
    'durNumberOfTimekeepers': 1,
    'durGroupsPerRound': 2,
    'durPilotsMax': 8,
    'durDrawLocked': 0,
    'durFlightPenalty': 3,
    'durNbrOfLanes': 0,
    'durRefHeight': 200,
    'durPenaltyUpToRefHeight': 0.5,
    'durPenaltyOverRefHeight': 3,
    'durAllowBackToBack': 0,
    'DurPointsPerSecond': 1,
    'F5JMotorRestartOption': 2,
    ...extra,
  };
  Map<String, Object?> member(
    int comp,
    int pilot, {
    String role = 'Plt',
    int team = 0,
    int retired = 0,
    int start = 0,
    String? cls,
    String? model,
    int omit = 0,
  }) => {
    'CompNo': comp,
    'PilotNo': pilot,
    if (cls != null) 'PilotClass': cls,
    'Team': team,
    'DrawFreq': 2.4,
    'Retired': retired,
    'StartNo': start,
    if (model != null) 'Model': model,
    'Role': role,
    'IsPilot': role == 'Hlp' || role == 'CD' || role == 'TM' ? 0 : 1,
    'OmitFromTeamScore': omit,
    'ModelData': '-1',
  };
  Map<String, Object?> pilot(int no, String first, String last) => {
    'PilotNo': no,
    'FirstName': first,
    'LastName': last,
    'Email': 'fixture$no@$_emailDomain',
    'Country': 'USA',
  };

  return _snapshotTables({
    'Comps': [
      // 9001: teams, team protection, every GliderScore drop slot used,
      // classes, models, numbering, roles.
      comp(
        9001,
        extra: {
          'Drop1AtRound': 3,
          'Drop2AtRound': 6,
          'Drop3AtRound': 9,
          'Drop4AtRound': 12,
          'Drop5AtRound': 15,
          'UseTeams': 1,
          'UseTeamProtection': 1,
          'NbrForTeamScore': 2,
          'UseClasses': 1,
          'UseModels': 1,
          'UsePilotNumbering': 1,
          'UseRoles': 1,
        },
      ),
      // 9002: retired pilots and every role; no teams.
      comp(9002, extra: {'UseRoles': 1, 'RoundOrTruncate': 0}),
      // 9003: an F5J comp with no Dur row (blocked, no configuration).
      comp(9003),
      // 9004: a class the importer does not know (skipped).
      comp(9004, cls: 'F3Z'),
    ],
    'CompPilots': [
      member(9001, 2001, team: 1, start: 1, cls: 'Sr', model: 'Alpha Glider'),
      member(9001, 2002, team: 1, start: 2, cls: 'Sr', model: 'Alpha Glider'),
      member(9001, 2003, team: 1, start: 3, cls: 'Jr', model: 'Beta Glider'),
      member(9001, 2004, team: 2, start: 4, cls: 'Sr', model: 'Gamma Glider'),
      member(9001, 2005, team: 2, start: 5, cls: 'Sr', omit: 1),
      member(9001, 2006, team: 2, start: 6, cls: 'Jr', model: 'beta glider '),
      member(9001, 2007, role: 'TM', team: 1),
      member(9002, 2001, start: 1),
      member(9002, 2002, retired: 1, start: 2),
      member(9002, 2003, retired: 1, start: 3),
      member(9002, 2004, role: 'TM/Plt', start: 4),
      member(9002, 2005, role: 'CD/Plt', start: 5),
      member(9002, 2006, role: 'CD'),
      member(9002, 2007, role: 'Hlp'),
      member(9002, 2008, role: 'TM'),
      member(9003, 2001),
      member(9003, 2002),
      member(9004, 2001),
    ],
    'Pilots': [
      pilot(2001, 'Ash', 'Fixtureone'),
      pilot(2002, 'Bo', 'Fixturetwo'),
      pilot(2003, 'Cy', 'Fixturethree'),
      pilot(2004, 'Di', 'Fixturefour'),
      pilot(2005, 'Ed', 'Fixturefive'),
      pilot(2006, 'Flo', 'Fixturesix'),
      pilot(2007, 'Gus', 'Fixtureseven'),
      pilot(2008, 'Hal', 'Fixtureeight'),
    ],
    'Roles': [
      {'Role': 'TM', 'RoleName': 'Team Manager'},
      {'Role': 'Plt', 'RoleName': 'Pilot'},
      {'Role': 'TM/Plt', 'RoleName': 'Team Manager/Pilot'},
      {'Role': 'CD/Plt', 'RoleName': 'Comp Director/Pilot'},
      {'Role': 'Hlp', 'RoleName': 'Helper'},
      {'Role': 'CD', 'RoleName': 'Competition Director'},
    ],
    'Dur': [
      dur(9001),
      dur(9002, extra: {'F5JMotorRestartOption': 0}),
    ],
    'DBParams': [
      {'Property': 'DBVersion', 'PRValue': '6.78'},
    ],
  });
}

// ---------------------------------------------------------------------------
// Validation of the lookup tables copied into the competition fixtures.

/// The GliderScore `Roles` lookup: code to English name. A file that differs
/// (an extra role, a renamed role, a personal value in a name) aborts the run
/// so someone looks at it, rather than silently committing it.
const _knownRoles = <String, String>{
  'TM': 'Team Manager',
  'Plt': 'Pilot',
  'TM/Plt': 'Team Manager/Pilot',
  'CD/Plt': 'Comp Director/Pilot',
  'Hlp': 'Helper',
  'CD': 'Competition Director',
};

/// Lower-cased lookup values that are excused from the leak scan because they
/// are validated against fixed patterns or the table above.
final _validatedLookupValues = <String>{
  for (final e in _knownRoles.entries) ...[
    e.key.toLowerCase(),
    e.value.toLowerCase(),
  ],
  for (final name in _knownLandingNames.values) name.toLowerCase(),
};

Never _abort(String message) {
  stderr.writeln('refusing to write: $message');
  exit(1);
}

List<Map<String, Object?>> _validatedRoles(List<Map<String, Object?>> rows) {
  final seen = <String, String>{};
  for (final row in rows) {
    final extra = row.keys.toSet().difference({'Role', 'RoleName'});
    if (extra.isNotEmpty) {
      _abort('Roles has unexpected column(s): ${extra.join(', ')}');
    }
    final code = row['Role'];
    final name = row['RoleName'];
    if (code is! String || name is! String || _knownRoles[code] != name) {
      _abort('Roles has a row that is not one of the six known roles');
    }
    seen[code] = name;
  }
  if (rows.length != _knownRoles.length || seen.length != _knownRoles.length) {
    _abort('Roles does not hold exactly the six known roles');
  }
  return [
    for (final e in _knownRoles.entries) {'Role': e.key, 'RoleName': e.value},
  ];
}

List<Map<String, Object?>> _validatedDbParams(List<Map<String, Object?>> rows) {
  final versions = [
    for (final r in rows)
      if (r['Property'] == 'DBVersion') r,
  ];
  if (versions.length != 1) {
    _abort('DBParams must hold exactly one DBVersion row');
  }
  final value = versions.single['PRValue'];
  if (value is! String || !RegExp(r'^\d+\.\d+$').hasMatch(value)) {
    _abort('DBParams DBVersion is not a version number');
  }
  // Every other property (names, locale, list separator) is dropped.
  return [
    {'Property': 'DBVersion', 'PRValue': value},
  ];
}

/// A `Dur` row holds numbers and the draw-option query string; anything else
/// aborts the run.
Map<String, Object?> _validDur(Map<String, Object?> row) {
  final option = RegExp(r'^([A-Za-z0-9]+=[A-Za-z0-9.]*&?)*$');
  // Older files hold a comma-coded list of digits instead.
  final comma = RegExp(r'^[0-9,]*$');
  for (final e in row.entries) {
    if (!_durKept.contains(e.key)) {
      continue;
    }
    final v = e.value;
    final ok = switch (e.key) {
      'durPilotsMin' =>
        v is String && (option.hasMatch(v) || comma.hasMatch(v)),
      _ => v == null || v is num,
    };
    if (!ok) {
      _abort('Dur column ${e.key} has an unexpected value shape');
    }
  }
  return row;
}

/// Names the columns of a source table that the allowlist drops, so a new
/// GliderScore column is a visible decision. Column names only, never values.
void _reportDroppedColumns(
  Map<String, (List<Map<String, Object?>>, Set<String>)> tables,
) {
  for (final e in tables.entries) {
    final dropped = {
      for (final row in e.value.$1)
        ...row.keys.where((k) => !e.value.$2.contains(k)),
    }.toList()..sort();
    if (dropped.isNotEmpty) {
      stdout.writeln('${e.key}: dropped column(s) ${dropped.join(', ')}');
    }
  }
}

/// Broken references a real file can hold, for the mapper to report rather
/// than crash on.
String _competitionIntegrityCases() {
  Map<String, Object?> comp(int no) => {
    'CompNo': no,
    'CompDate': '06/14/26 00:00:00',
    'CompID': 'FIXTURE$no',
    'CompName': 'Fixture Open $no',
    'GSCompClass': 'F5J',
  };
  Map<String, Object?> member(int comp, int pilot) => {
    'CompNo': comp,
    'PilotNo': pilot,
    'Role': 'Plt',
  };
  return _snapshotTables({
    'Comps': [comp(9101), comp(9102), comp(9102)],
    'CompPilots': [
      member(9101, 2101),
      // The same pilot twice in one competition.
      member(9101, 2102),
      member(9101, 2102),
      // A participant with no row in Pilots.
      member(9101, 2999),
      member(9102, 2101),
    ],
    'Pilots': [
      {'PilotNo': 2101, 'FirstName': 'Ivy', 'LastName': 'Integrityone'},
      {'PilotNo': 2102, 'FirstName': 'Jem', 'LastName': 'Integritytwo'},
    ],
    'Dur': [
      {'CompNo': 9101, 'durTargetTime': 600},
      {'CompNo': 9102, 'durTargetTime': 600},
    ],
  });
}

/// Hand-built draws the real file does not hold: a flight credited to a
/// different round than it was drawn in, which the importer refuses.
String _drawEdgeCases() {
  Map<String, Object?> comp(int no) => {
    'CompNo': no,
    'CompDate': '06/14/26 00:00:00',
    'CompID': 'FIXTURE$no',
    'CompName': 'Fixture Open $no',
    'CompVenue': 'Example Field',
    'GSCompClass': 'F5J',
  };
  Map<String, Object?> member(int comp, int pilot) => {
    'CompNo': comp,
    'PilotNo': pilot,
    'Role': 'Plt',
  };
  Map<String, Object?> flight(
    int comp,
    int round,
    int group,
    int pilot,
    int seq, {
    int? credit,
    bool scored = false,
  }) => {
    'CompNo': comp,
    'TaskNo': 1,
    'RoundNo': round,
    'GroupNo': group,
    'ReFlightNo': 0,
    'PilotNo': pilot,
    'SeqNo': seq,
    'OriginalRoundNo': credit ?? round,
    'Updated': scored ? 'True' : 'False',
    if (scored) ...{'RawScore': 900, 'NormalisedScore': 1000},
  };
  return _snapshotTables({
    'Comps': [comp(9201)],
    'CompPilots': [
      for (final pilot in [2201, 2202, 2203, 2204]) member(9201, pilot),
    ],
    'Pilots': [
      {'PilotNo': 2201, 'FirstName': 'Kim', 'LastName': 'Drawone'},
      {'PilotNo': 2202, 'FirstName': 'Lou', 'LastName': 'Drawtwo'},
      {'PilotNo': 2203, 'FirstName': 'Max', 'LastName': 'Drawthree'},
      {'PilotNo': 2204, 'FirstName': 'Ned', 'LastName': 'Drawfour'},
    ],
    'Dur': [
      {'CompNo': 9201, 'durTargetTime': 600, 'durGroupsPerRound': 2},
    ],
    'Scores': [
      flight(9201, 1, 1, 2201, 1, scored: true),
      flight(9201, 1, 1, 2202, 2, scored: true),
      flight(9201, 1, 2, 2203, 1, scored: true),
      flight(9201, 1, 2, 2204, 2, scored: true),
      // Drawn in round 2, credited to round 1: a moved credit.
      flight(9201, 2, 1, 2201, 1, credit: 1),
      flight(9201, 2, 1, 2203, 2),
      flight(9201, 2, 2, 2202, 1),
      flight(9201, 2, 2, 2204, 2),
    ],
  });
}

/// GliderScore's own landing table names. They are lookup values, not
/// personal data, and are checked against this list.
const _knownLandingNames = <int, String>{
  0: 'None',
  1: 'FAI 15 Metre Tape',
  2: 'F3J Enter Dist',
  3: 'F3J Enter Points',
  4: 'F3J Enter Pts to 2m',
  5: 'F5J Enter Distance',
  6: 'ALES Landing',
  7: 'F3J Enter Cms',
  8: 'F5B Enter Distance',
  9: 'F5J Enter Points',
  10: 'FAI 15m Points',
};

List<Map<String, Object?>> _validLndgNames(List<Map<String, Object?>> rows) {
  for (final row in rows) {
    final extra = row.keys.toSet().difference({'LndgNo', 'Name'});
    final no = row['LndgNo'];
    if (extra.isNotEmpty ||
        no is! num ||
        _knownLandingNames[no.toInt()] != row['Name']) {
      _abort('LndgNames has a row that is not one of the known tables');
    }
  }
  return rows;
}

List<Map<String, Object?>> _validLndgPoints(List<Map<String, Object?>> rows) {
  for (final row in rows) {
    if (row.keys.toSet().difference({
          'LndgNo',
          'Distance',
          'Points',
        }).isNotEmpty ||
        row.values.any((v) => v is! num)) {
      _abort('LndgPoints has an unexpected column or value shape');
    }
  }
  return rows;
}

/// Hand-built score cases the real file does not hold: a landing table with
/// one value that matches nothing (a partial match), a table only the
/// competition has (reconstructed), a retired pilot who never scored, a
/// subset re-flight (refused) and two tasks whose rounds overlap (refused).
String _scoreEdgeCases() {
  Map<String, Object?> comp(int no) => {
    'CompNo': no,
    'CompDate': '06/14/26 00:00:00',
    'CompID': 'FIXTURE$no',
    'CompName': 'Fixture Open $no',
    'CompVenue': 'Example Field',
    'GSCompClass': 'F5J',
  };
  Map<String, Object?> member(int comp, int pilot, {bool retired = false}) => {
    'CompNo': comp,
    'PilotNo': pilot,
    'Role': 'Plt',
    'IsPilot': 1,
    if (retired) 'Retired': 1,
  };
  Map<String, Object?> dur(int comp, int landing, {int groups = 1}) => {
    'CompNo': comp,
    'durTargetTime': 600,
    'durGroupsPerRound': groups,
    'durLndg': landing,
    'durRefHeight': 200,
    'durPenaltyUpToRefHeight': 0.5,
    'durPenaltyOverRefHeight': 3,
    'F5JMotorRestartOption': 2,
  };
  Map<String, Object?> flight(
    int comp,
    int round,
    int pilot,
    int seq, {
    int task = 1,
    int group = 1,
    int reflight = 0,
    int? landing,
    int? raw,
  }) => {
    'CompNo': comp,
    'TaskNo': task,
    'RoundNo': round,
    'GroupNo': group,
    'ReFlightNo': reflight,
    'PilotNo': pilot,
    'SeqNo': seq,
    'DrawFreq': 2.4,
    'Time1Mins': raw == null ? 0 : 1000,
    'FlightScoreDeduction': raw == null ? 0 : 100,
    'Landing': landing ?? 0,
    'RawScore': raw ?? 0,
    'NormalisedScore': raw == null ? 0 : 1000,
    'OriginalRoundNo': round,
    'Updated': raw == null ? 'False' : 'True',
    'F5JMotorReStarted': 0,
  };
  // Points table 9 holds 5..50; the landing 7 matches no entry.
  final tableNine = [
    for (var p = 5; p <= 50; p += 5) {'LndgNo': 9, 'Distance': p, 'Points': p},
  ];
  // A table only 9302 has: three entries with points that differ from
  // the shipped tables.
  final custom = [
    {'LndgNo': 11, 'Distance': 1, 'Points': 40},
    {'LndgNo': 11, 'Distance': 2, 'Points': 25},
    {'LndgNo': 11, 'Distance': 3, 'Points': 10},
  ];
  return _snapshotTables({
    'Comps': [
      for (final no in [9301, 9302, 9303, 9304]) comp(no),
    ],
    'CompPilots': [
      for (final no in [9301, 9302, 9303, 9304])
        for (final pilot in [2301, 2302, 2303, 2304])
          member(no, pilot, retired: no == 9302 && pilot == 2304),
    ],
    'Pilots': [
      {'PilotNo': 2301, 'FirstName': 'Orla', 'LastName': 'Scoreone'},
      {'PilotNo': 2302, 'FirstName': 'Pat', 'LastName': 'Scoretwo'},
      {'PilotNo': 2303, 'FirstName': 'Quin', 'LastName': 'Scorethree'},
      {'PilotNo': 2304, 'FirstName': 'Rae', 'LastName': 'Scorefour'},
    ],
    'Dur': [dur(9301, 9), dur(9302, 11), dur(9303, 9, groups: 2), dur(9304, 9)],
    'LndgNames': [
      {'LndgNo': 9, 'Name': 'F5J Enter Points'},
      {'LndgNo': 11, 'Name': 'Example Table'},
    ],
    'LndgPoints': [...tableNine, ...custom],
    'Scores': [
      // 9301: one landing (7) matches nothing in the pinned table.
      flight(9301, 1, 2301, 1, landing: 50, raw: 640),
      flight(9301, 1, 2302, 2, landing: 7, raw: 600),
      flight(9301, 1, 2303, 3, landing: 45, raw: 590),
      flight(9301, 1, 2304, 4, landing: 40, raw: 580),
      // 9302: landing values come from the competition's own table; pilot
      // 2304 is retired and never scored.
      flight(9302, 1, 2301, 1, landing: 1, raw: 640),
      flight(9302, 1, 2302, 2, landing: 2, raw: 600),
      flight(9302, 1, 2303, 3, landing: 3, raw: 590),
      flight(9302, 1, 2304, 4),
      // 9303: a re-flight of two of the four pilots of a group (a subset).
      flight(9303, 1, 2301, 1, landing: 50, raw: 640),
      flight(9303, 1, 2302, 2, landing: 45, raw: 600),
      flight(9303, 1, 2303, 3, landing: 40, raw: 590),
      flight(9303, 1, 2304, 4, landing: 35, raw: 580),
      flight(9303, 1, 2301, 1, reflight: 1, landing: 50, raw: 645),
      flight(9303, 1, 2302, 2, reflight: 1, landing: 45, raw: 605),
      // 9304: task 1 holds rounds 1 and 2, task 2 starts again at round 2.
      flight(9304, 1, 2301, 1, landing: 50, raw: 640),
      flight(9304, 1, 2302, 2, landing: 45, raw: 600),
      flight(9304, 2, 2301, 1, landing: 50, raw: 640),
      flight(9304, 2, 2302, 2, landing: 45, raw: 600),
      flight(9304, 2, 2301, 1, task: 2, landing: 50, raw: 640),
      flight(9304, 2, 2302, 2, task: 2, landing: 45, raw: 600),
    ],
  });
}
