import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Runs `scripts/scrub_gliderscore_pilots.dart` on tiny hand-made inputs and
/// proves it refuses to write when a lookup table holds anything unexpected.
void main() {
  final script = File('../../scripts/scrub_gliderscore_pilots.dart').absolute;

  late Directory work;
  setUp(() => work = Directory.systemTemp.createTempSync('scrub_test_'));
  tearDown(() => work.deleteSync(recursive: true));

  void jsonl(String name, List<Map<String, Object?>> rows) {
    File('${work.path}/in/$name.jsonl')
      ..createSync(recursive: true)
      ..writeAsStringSync(rows.map(jsonEncode).join('\n'));
  }

  const knownRoles = <Map<String, Object?>>[
    {'Role': 'TM', 'RoleName': 'Team Manager'},
    {'Role': 'Plt', 'RoleName': 'Pilot'},
    {'Role': 'TM/Plt', 'RoleName': 'Team Manager/Pilot'},
    {'Role': 'CD/Plt', 'RoleName': 'Comp Director/Pilot'},
    {'Role': 'Hlp', 'RoleName': 'Helper'},
    {'Role': 'CD', 'RoleName': 'Competition Director'},
  ];

  void writeInputs({
    List<Map<String, Object?>> roles = knownRoles,
    List<Map<String, Object?>>? dbParams,
    Map<String, Object?> dur = const {},
  }) {
    jsonl('Pilots', [
      {'PilotNo': 1, 'FirstName': 'Real', 'LastName': 'Person'},
    ]);
    jsonl('Comps', [
      {
        'CompNo': 22,
        'CompName': 'Real Event',
        'CompVenue': 'Real Field',
        'GSCompClass': 'F5J',
        'CompDate': '03/18/22 00:00:00',
      },
    ]);
    jsonl('CompPilots', [
      {'CompNo': 22, 'PilotNo': 1, 'Role': 'Plt'},
    ]);
    jsonl('Roles', roles);
    jsonl(
      'DBParams',
      dbParams ??
          [
            {'Property': 'DBVersion', 'PRValue': '6.78'},
          ],
    );
    jsonl('Dur', [
      {'CompNo': 22, 'durTargetTime': 600, ...dur},
    ]);
  }

  ProcessResult run() => Process.runSync(Platform.resolvedExecutable, [
    script.path,
    '${work.path}/in/Pilots.jsonl',
    '${work.path}/out',
    '${work.path}/in',
  ]);

  bool wroteNothing() => !Directory('${work.path}/out').existsSync();

  test('clean inputs produce the fixtures', () {
    writeInputs();
    final result = run();
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(File('${work.path}/out/comps_reference.json').existsSync(), isTrue);
  });

  test('a personal value in a Roles name aborts the run', () {
    writeInputs(
      roles: [
        ...knownRoles.take(5),
        {'Role': 'CD', 'RoleName': 'Pat Realperson'},
      ],
    );
    final result = run();
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('Roles'));
    expect(wroteNothing(), isTrue);
  });

  test('an extra Roles column or row aborts the run', () {
    writeInputs(
      roles: [
        for (final r in knownRoles) {...r, 'Owner': 'Pat Realperson'},
      ],
    );
    expect(run().exitCode, isNot(0));
    writeInputs(
      roles: [
        ...knownRoles,
        {'Role': 'Zz', 'RoleName': 'Extra'},
      ],
    );
    expect(run().exitCode, isNot(0));
    expect(wroteNothing(), isTrue);
  });

  test('a duplicated known role aborts the run', () {
    writeInputs(roles: [...knownRoles, knownRoles.first]);
    final result = run();
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('Roles'));
    expect(wroteNothing(), isTrue);
  });

  test('a DBVersion that is not a version number aborts the run', () {
    writeInputs(
      dbParams: [
        {'Property': 'DBVersion', 'PRValue': 'Pat Realperson'},
      ],
    );
    final result = run();
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('DBVersion'));
    expect(wroteNothing(), isTrue);
  });

  test('other DBParams properties are dropped, not copied', () {
    writeInputs(
      dbParams: [
        {'Property': 'NativeName', 'PRValue': 'Real Installation Name'},
        {'Property': 'DBVersion', 'PRValue': '6.78'},
      ],
    );
    final result = run();
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final text = File('${work.path}/out/comps_reference.json')
        .readAsStringSync();
    expect(text, isNot(contains('Real Installation Name')));
    expect(text, isNot(contains('NativeName')));
  });

  test('a text value in a Dur number column aborts the run', () {
    writeInputs(dur: {'durTargetTime': 'Pat Realperson'});
    final result = run();
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('Dur'));
    expect(wroteNothing(), isTrue);
  });

  test('original comp, venue and pilot names never reach the output', () {
    writeInputs();
    expect(run().exitCode, 0);
    for (final f in Directory('${work.path}/out').listSync()) {
      final text = (f as File).readAsStringSync();
      expect(text, isNot(contains('Real Event')));
      expect(text, isNot(contains('Real Field')));
    }
  });
}
