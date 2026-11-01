// Builds the anonymised GliderScore pilot fixtures used by the pilot import
// tests (#697) from a real GliderScore database.
//
// The real file holds names and email addresses, so nothing from it is
// committed: this script replaces every identifying value with a stable fake
// and refuses to write anything that still contains an original name or email.
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
// Deterministic: same input, same output. Needs only the Dart SDK.

import 'dart:convert';
import 'dart:io';

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
  if (args.length != 2) {
    stderr.writeln(
      'usage: dart scripts/scrub_gliderscore_pilots.dart '
      '<pilots.jsonl> <output dir>',
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

  final files = <String, List<Map<String, Object?>>>{
    'pilots_reference.json': scrubbed,
    'pilots_edge_cases.json': _edgeCases(),
    'pilots_old_columns.json': [
      for (final row in scrubbed.take(12))
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
      for (final row in scrubbed.take(5))
        {...row, 'FutureColumn': 'x', 'AnotherNewThing': 7},
    ],
  };

  final rendered = {
    for (final entry in files.entries) entry.key: _snapshot(entry.value),
  };
  _refuseLeaks(original, rendered.values);

  outDir.createSync(recursive: true);
  for (final entry in rendered.entries) {
    File('${outDir.path}/${entry.key}').writeAsStringSync(entry.value);
    stdout.writeln('wrote ${entry.key}');
  }
}

Map<String, Object?> _scrub(Map<String, Object?> row) {
  final no = (row['PilotNo'] as num).toInt();
  final isTestUser = ((row['LastName'] as String?) ?? '')
      .trim()
      .toUpperCase()
      .startsWith('ZZ');
  final last =
      _lastNames[no % _lastNames.length] +
      (no ~/ _lastNames.length == 0 ? '' : '${no ~/ _lastNames.length}');
  return {
    for (final entry in row.entries)
      entry.key: switch (entry.key) {
        'FirstName' => _firstNames[(no * 7) % _firstNames.length],
        'LastName' => isTestUser ? 'ZZ$last' : last,
        'Email' => _hasText(entry.value) ? 'fixture$no@$_emailDomain' : null,
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
    for (final key in const ['FirstName', 'LastName', 'Email']) {
      final value = row[key];
      if (value is String && value.trim().length >= 3) {
        secrets.add(value.trim().toLowerCase());
      }
    }
  }
  final text = outputs.join('\n').toLowerCase();
  final leaked = [
    for (final secret in secrets)
      if (RegExp('(^|[^a-z])${RegExp.escape(secret)}(\$|[^a-z])')
          .hasMatch(text))
        secret,
  ];
  if (leaked.isNotEmpty) {
    stderr.writeln(
      'refusing to write: ${leaked.length} original value(s) would appear in '
      'the fixtures. Change the fake pools or the hand-built rows.',
    );
    exit(1);
  }
}
