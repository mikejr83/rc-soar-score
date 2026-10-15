import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

class _FakeRunner implements GliderScoreImportRunner {
  _FakeRunner({
    this.available = true,
    this.unavailableReason,
    this.tables = const [],
    this.rowsByTable = const {},
  });

  final bool available;
  final String? unavailableReason;
  final List<String> tables;
  final Map<String, List<Map<String, Object?>>> rowsByTable;

  @override
  Future<ImportAvailability> availability() async => ImportAvailability(
    available: available,
    reason: unavailableReason,
  );

  @override
  Future<List<String>> listTables(String dbPath) async => tables;

  @override
  Future<ImportTableStream> exportTable(String dbPath, String table) async {
    return ImportTableStream(
      table: table,
      rows: Stream.fromIterable(rowsByTable[table] ?? const []),
    );
  }
}

Map<String, Object?> _row(Object? id) => {'id': id};

void main() {
  group('GliderScoreImportService.importFile', () {
    test('imports every table in database order when none are requested',
        () async {
      final service = GliderScoreImportService();
      final result = await service.importFile(
        _FakeRunner(
          tables: const ['Scores', 'Aircrafts'],
          rowsByTable: const {
            'Scores': [
              {'id': 1, 'name': 'A'},
              {'id': 2, 'name': 'B'},
            ],
            'Aircrafts': [
              {'id': 10, 'type': '18m'},
            ],
          },
        ),
        dbPath: 'C:\\data\\GliderScoreData.mdb',
      );

      expect(result.id, isA<Id>());
      expect(result.sourceDbFile, 'GliderScoreData.mdb');
      expect(result.tables.map((t) => t.name), ['Scores', 'Aircrafts']);
      expect(result.tables.first.rows, [
        {'id': 1, 'name': 'A'},
        {'id': 2, 'name': 'B'},
      ]);
      expect(result.tables.first.rowCount, 2);
      expect(result.tables.first.rowCapExceeded, isFalse);
    });

    test('imports only the requested tables, in the requested order',
        () async {
      final service = GliderScoreImportService();
      final result = await service.importFile(
        _FakeRunner(
          tables: const ['Scores', 'Aircrafts', 'Pilots'],
          rowsByTable: {
            'Scores': [_row(1)],
            'Aircrafts': [_row(10)],
            'Pilots': [_row(100)],
          },
        ),
        dbPath: 'database.mdb',
        tables: {'Pilots', 'Scores'},
      );

      expect(result.tables.map((t) => t.name), ['Pilots', 'Scores']);
    });

    test('throws ImportTableMissingError for a table the database lacks',
        () async {
      final service = GliderScoreImportService();
      final runner = _FakeRunner(tables: const ['Scores']);

      await expectLater(
        service.importFile(runner, dbPath: 'db.mdb', tables: {'Missing'}),
        throwsA(
          isA<ImportTableMissingError>()
              .having((e) => e.code, 'code', 'import_table_not_found')
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', contains('Missing')),
        ),
      );
    });

    test('throws ImportUnsupportedFileError for a file without a .mdb name',
        () async {
      final service = GliderScoreImportService();

      await expectLater(
        service.importFile(_FakeRunner(), dbPath: 'C:\\data\\scores.json'),
        throwsA(
          isA<ImportUnsupportedFileError>()
              .having((e) => e.code, 'code', 'import_unsupported')
              .having((e) => e.statusCode, 'statusCode', 415),
        ),
      );
    });

    test('accepts an upper-case extension and a blank-padded path',
        () async {
      final service = GliderScoreImportService();
      final result = await service.importFile(
        _FakeRunner(tables: const []),
        dbPath: '   C:\\DATA\\DB.MDB   ',
      );

      expect(result.sourceDbFile, 'DB.MDB');
      expect(result.tables, isEmpty);
    });

    test('throws ImportUnavailableError when the helpers are missing',
        () async {
      final service = GliderScoreImportService();
      final runner = _FakeRunner(
        available: false,
        unavailableReason: 'the gs_importer helpers were not found',
      );

      await expectLater(
        service.importFile(runner, dbPath: 'db.mdb'),
        throwsA(
          isA<ImportUnavailableError>()
              .having((e) => e.code, 'code', 'import_unavailable')
              .having((e) => e.statusCode, 'statusCode', 503)
              .having(
                (e) => e.message,
                'message',
                'the gs_importer helpers were not found',
              ),
        ),
      );
    });

    test('reports a default reason when the runner gives none', () async {
      final service = GliderScoreImportService();

      Object? error;
      try {
        await service.importFile(_FakeRunner(available: false), dbPath: 'db.mdb');
      } on Object catch (e) {
        error = e;
      }

      expect(error, isA<ImportUnavailableError>());
      expect((error as ImportUnavailableError).message, isNotEmpty);
    });

    test('counts every row but keeps only the first rowCap of a table',
        () async {
      final service = GliderScoreImportService(rowCap: 3);
      final result = await service.importFile(
        _FakeRunner(
          tables: const ['Scores'],
          rowsByTable: {
            'Scores': [_row(1), _row(2), _row(3), _row(4), _row(5)],
          },
        ),
        dbPath: 'db.mdb',
      );

      final table = result.tables.single;
      expect(table.rowCount, 5);
      expect(table.rows, [_row(1), _row(2), _row(3)]);
      expect(table.rowCapExceeded, isTrue);
    });

    test('serializes the result with its schema, id and snake_case keys',
        () async {
      final service = GliderScoreImportService();
      final result = await service.importFile(
        _FakeRunner(
          tables: const ['Scores'],
          rowsByTable: {'Scores': [_row(1)]},
        ),
        dbPath: 'C:\\data\\db.mdb',
      );

      final json = result.toJson();
      expect(json['schema'], GliderScoreImportResult.schema);
      expect(json['id'], result.id.value);
      expect(json['sourceDbFile'], 'db.mdb');
      expect(json, isNot(contains('dbPath')));
      expect(
        (json['tables']! as List).single as Map<String, Object?>,
        containsPair('rowCount', 1),
      );
    });
  });

  group('GliderScoreImportError', () {
    test('carries its own status and code', () {
      expect(
        [
          ImportUnavailableError('x'),
          ImportDatabaseNotFoundError('x'),
          ImportUnsupportedFileError('x'),
          ImportCorruptDatabaseError('x'),
          ImportMalformedTableError('x'),
          ImportTableMissingError('x'),
        ].map((e) => e.statusCode),
        [503, 404, 415, 422, 422, 404],
      );
      expect(
        [
          ImportUnavailableError('x'),
          ImportDatabaseNotFoundError('x'),
          ImportUnsupportedFileError('x'),
          ImportCorruptDatabaseError('x'),
          ImportMalformedTableError('x'),
          ImportTableMissingError('x'),
        ].map((e) => e.code),
        [
          'import_unavailable',
          'import_not_found',
          'import_unsupported',
          'import_corrupt',
          'import_malformed',
          'import_table_not_found',
        ],
      );
    });
  });
}
