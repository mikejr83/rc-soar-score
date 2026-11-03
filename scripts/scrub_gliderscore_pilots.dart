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
  final roles = table('Roles');
  final dur = table('Dur');
  final dbParams = table('DBParams');

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
      'CompID': 'FIXTURE$no',
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
  }) {
    final nos = compNos.toSet();
    bool inScope(Map<String, Object?> r) => nos.contains(r['CompNo']);
    final cp = [
      for (final r in compPilots)
        if (inScope(r)) compPilotRow(r),
    ];
    final pilotNos = {for (final r in cp) (r['PilotNo']! as num).toInt()};
    return _snapshotTables({
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
      if (withDbParams)
        'DBParams': [
          for (final r in dbParams)
            if (r['Property'] == 'DBVersion') r,
        ],
    });
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
    'comps_edge_cases.json': _competitionEdgeCases(),
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
  final text = out.values
      .join('\n')
      .toLowerCase()
      .replaceAll('@$_emailDomain', '');
  final leaked = [
    for (final secret in secrets)
      // Fixture ids and fake names are built from these words on purpose.
      if (!secret.startsWith('fixture') &&
          !secret.startsWith('example') &&
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

String _snapshotTables(Map<String, List<Map<String, Object?>>> tables) {
  final snapshot = <String, Object?>{
    'schema': 'gs-import/v1',
    'id': _snapshotId,
    'sourceDbFile': 'GliderScoreData.mdb',
    'tables': [
      for (final e in tables.entries)
        {
          'name': e.key,
          'rowCount': e.value.length,
          'rowCapExceeded': false,
          'rows': e.value,
        },
    ],
  };
  return '${const JsonEncoder.withIndent('  ').convert(snapshot)}\n';
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
