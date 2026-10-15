import 'dart:convert';
import 'dart:io' as io;

import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

void main() {
  group('GliderScoreImportProcessRunner', () {
    late io.Directory helperDir;

    setUp(() {
      helperDir = io.Directory.systemTemp.createTempSync('gs_importer_test');
      io.File('${helperDir.path}${io.Platform.pathSeparator}mdb-json.exe')
          .writeAsStringSync('fake');
    });

    tearDown(() {
      helperDir.deleteSync(recursive: true);
    });

    /// A stub process executor that answers with [stdout] for whatever it is
    /// run, recording the last argument vector it saw.
    Future<io.ProcessResult> Function(List<String>) stub(
      Object? stdout, {
      int exitCode = 0,
      Object? stderr,
      void Function(List<String>)? expectArgs,
    }) {
      return (args) async {
        expectArgs?.call(args);
        return io.ProcessResult(
          1,
          exitCode,
          _stringToBytes(stdout),
          _stringToBytes(stderr),
        );
      };
    }

    test('finds the helpers in the override directory', () async {
      final runner = GliderScoreImportProcessRunner(
        helperDirectory: helperDir.path,
      );

      final availability = await runner.availability();
      expect(availability.available, isTrue);
      expect(
        availability.executablePath,
        '${helperDir.path}${io.Platform.pathSeparator}mdb-json.exe',
      );
    });

    test(
      'is unavailable when mdb-json.exe is missing from the folder',
      () async {
        final empty = io.Directory.systemTemp.createTempSync('gs_empty');
        final runner = GliderScoreImportProcessRunner(
          helperDirectory: empty.path,
        );

        final availability = await runner.availability();
        expect(availability.available, isFalse);
        expect(availability.reason, contains('mdb-json.exe'));
        empty.deleteSync(recursive: true);
      },
    );

    test('locates the gs_importer folder next to the executable', () async {
      final install = io.Directory.systemTemp.createTempSync('gs_install');
      final helperFolder = io.Directory(
        '${install.path}${io.Platform.pathSeparator}gs_importer',
      )..createSync();
      io.File('${helperFolder.path}${io.Platform.pathSeparator}mdb-json.exe')
          .writeAsStringSync('fake');
      final runner = GliderScoreImportProcessRunner(
        resolvedExecutable: () =>
            '${install.path}${io.Platform.pathSeparator}soar_score_contest.exe',
      );

      final availability = await runner.availability();
      expect(availability.available, isTrue);
      expect(
        availability.executablePath,
        contains('gs_importer${io.Platform.pathSeparator}mdb-json.exe'),
      );
      install.deleteSync(recursive: true);
    });

    test('lists the tables the helper prints, one per name', () async {
      final runner = GliderScoreImportProcessRunner(
        helperDirectory: helperDir.path,
        runProcess: stub('Scores Pilots Compils\n'),
        databaseFileExists: (_) => true,
      );

      final tables = await runner.listTables('C:\\data\\db.mdb');
      expect(tables, ['Scores', 'Pilots', 'Compils']);
    });

    test('passes the database path as the only mdb-tables argument', () async {
      final runner = GliderScoreImportProcessRunner(
        helperDirectory: helperDir.path,
        runProcess: stub(
          '',
          expectArgs: (args) {
            expect(args.length, 2);
            expect(args.last, 'C:\\data\\db.mdb');
            expect(args.first, endsWith('mdb-tables.exe'));
          },
        ),
        databaseFileExists: (_) => true,
      );

      await runner.listTables('C:\\data\\db.mdb');
    });

    test('maps a failed mdb-tables run to a corrupt-database error', () async {
      final runner = GliderScoreImportProcessRunner(
        helperDirectory: helperDir.path,
        runProcess: stub('', exitCode: 1, stderr: 'mdb-tables: cannot open db'),
        databaseFileExists: (_) => true,
      );

      await expectLater(
        runner.listTables('C:\\data\\broken.mdb'),
        throwsA(
          isA<ImportCorruptDatabaseError>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.code, 'code', 'import_corrupt')
              .having(
                (e) => e.message,
                'message',
                allOf(contains('code 1'), contains('cannot open db')),
              ),
        ),
      );
    });

    test('truncates long stderr in the corrupt-database message', () async {
      final runner = GliderScoreImportProcessRunner(
        helperDirectory: helperDir.path,
        runProcess: stub('', exitCode: 2, stderr: 'f' * 600),
        databaseFileExists: (_) => true,
      );

      final ImportCorruptDatabaseError caught;
      try {
        await runner.listTables('db.mdb');
        fail('expected a corrupt-database error');
      } on ImportCorruptDatabaseError catch (e) {
        caught = e;
      }

      expect(caught.message, contains('…'));
      expect(caught.message.length, lessThan(600));
    });

    test('maps a spawn failure to an availability error', () async {
      final runner = GliderScoreImportProcessRunner(
        helperDirectory: helperDir.path,
        runProcess: (args) async => throw io.ProcessException(
          args.first,
          args.skip(1).toList(),
          'not found',
        ),
        databaseFileExists: (_) => true,
      );

      await expectLater(
        runner.listTables('db.mdb'),
        throwsA(
          isA<ImportUnavailableError>()
              .having((e) => e.statusCode, 'statusCode', 503)
              .having((e) => e.code, 'code', 'import_unavailable')
              .having((e) => e.message, 'message', contains('not found')),
        ),
      );
    });

    test('reports a missing database file as not found', () async {
      final missing = r'C:\data\gone.mdb';
      final runner = GliderScoreImportProcessRunner(
        helperDirectory: helperDir.path,
        databaseFileExists: (_path) => false,
      );

      await expectLater(
        runner.listTables(missing),
        throwsA(
          isA<ImportDatabaseNotFoundError>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.code, 'code', 'import_not_found')
              .having((e) => e.message, 'message', contains(missing)),
        ),
      );
      await expectLater(
        runner.exportTable(missing, 'Scores'),
        throwsA(isA<ImportDatabaseNotFoundError>()),
      );
    });

    test('streams one decoded row per JSON line, skipping blanks', () async {
      final stream =
          ('{"CompNo":1,"CompDate":"2009-03-06T00:00:00"}\n'
          '\n'
          '{"CompNo":2}\n');
      final runner = GliderScoreImportProcessRunner(
        helperDirectory: helperDir.path,
        runProcess: stub(
          stream,
          expectArgs: (args) {
            expect(args.length, 5);
            expect(args.first, endsWith('mdb-json.exe'));
            expect(args.skip(1).take(2).toList(), ['-T', '%Y-%m-%dT%H:%M:%S']);
            expect(args.sublist(3), ['C:\\data\\db.mdb', 'Scores']);
          },
        ),
        databaseFileExists: (_) => true,
      );

      final table = await runner.exportTable('C:\\data\\db.mdb', 'Scores');
      expect(table.table, 'Scores');
      final rows = await table.rows.toList();
      expect(rows, [
        {'CompNo': 1, 'CompDate': '2009-03-06T00:00:00'},
        {'CompNo': 2},
      ]);
    });

    test('decodes stdout as UTF-8, not the system encoding', () async {
      final runner = GliderScoreImportProcessRunner(
        helperDirectory: helperDir.path,
        runProcess: stub(utf8.encode('{"name":"Léa"}\n')),
        databaseFileExists: (_) => true,
      );

      final rows = await (await runner.exportTable(
        'db.mdb',
        'Pilots',
      )).rows.toList();
      expect(rows.single, {'name': 'Léa'});
    });

    test('rejects a row that is not a JSON object', () async {
      final runner = GliderScoreImportProcessRunner(
        helperDirectory: helperDir.path,
        runProcess: stub('{"id":1}\n42\n'),
        databaseFileExists: (_) => true,
      );

      await expectLater(
        runner.exportTable('db.mdb', 'Scores'),
        throwsA(
          isA<ImportMalformedTableError>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.code, 'code', 'import_malformed')
              .having((e) => e.message, 'message', contains('row 2')),
        ),
      );
    });

    test('rejects a row that does not parse as JSON', () async {
      final runner = GliderScoreImportProcessRunner(
        helperDirectory: helperDir.path,
        runProcess: stub('{oops}\n'),
        databaseFileExists: (_) => true,
      );

      await expectLater(
        runner.exportTable('db.mdb', 'Scores'),
        throwsA(
          isA<ImportMalformedTableError>().having(
            (e) => e.message,
            'message',
            contains('row 1'),
          ),
        ),
      );
    });

    test('a failed mdb-json run is a corrupt-database error', () async {
      final runner = GliderScoreImportProcessRunner(
        helperDirectory: helperDir.path,
        runProcess: stub('', exitCode: 3, stderr: 'mdb-json: table not found'),
        databaseFileExists: (_) => true,
      );

      await expectLater(
        runner.exportTable('db.mdb', 'Nope'),
        throwsA(
          isA<ImportCorruptDatabaseError>().having(
            (e) => e.message,
            'message',
            contains('table not found'),
          ),
        ),
      );
    });
  });

  group('integration against the vendored helpers (opt-in)', () {
    test('lists the reference database tables and exports Scores', () async {
      const defaultDb = r'S:\Shared\GliderScoreData.mdb';
      final dbPath =
          io.Platform.environment['GS_IMPORTER_TEST_DB'] ?? defaultDb;
      final binDir = [
        io.Directory.current.path,
        '..',
        '..',
        'tools',
        'gs_importer',
        'bin',
        'x86',
      ].join(io.Platform.pathSeparator);
      if (!io.Platform.isWindows ||
          !io.File('$binDir${io.Platform.pathSeparator}mdb-json.exe')
              .existsSync() ||
          !io.File(dbPath).existsSync()) {
        return; // not Windows, helpers not checked out, or DB not present
      }

      final runner = GliderScoreImportProcessRunner(helperDirectory: binDir);
      expect((await runner.availability()).available, isTrue);

      final tables = await runner.listTables(dbPath);
      expect(tables, containsAll(['Scores', 'Pilots', 'Comps']));
      expect(tables.length, greaterThan(10));

      final stream = await runner.exportTable(dbPath, 'Scores');
      final rows = await stream.rows.toList();
      expect(rows.length, greaterThan(6000));
      expect(rows.first, isA<Map<String, Object?>>());
      expect(rows.first.keys, isNotEmpty);
    });
  });
}

List<int> _stringToBytes(Object? value) => value == null
    ? const []
    : value is String
    ? utf8.encode(value)
    : value as List<int>;
