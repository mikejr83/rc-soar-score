import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');

const _dbPath = 'C:\\data\\GliderScoreData.mdb';

/// A [GliderScoreImportRunner] whose answers the test controls.
class FakeGliderScoreImportRunner implements GliderScoreImportRunner {
  FakeGliderScoreImportRunner({
    this.available = true,
    this.unavailableReason = 'helpers not present',
    this.allTables = const [],
    this.rowsByTable = const {},
    this.listError,
    this.exportError,
  });

  final bool available;
  final String unavailableReason;
  final List<String> allTables;
  final Map<String, List<Map<String, Object?>>> rowsByTable;
  final Object? listError;
  final Object? exportError;

  @override
  Future<ImportAvailability> availability() async => ImportAvailability(
    available: available,
    reason: available ? null : unavailableReason,
  );

  @override
  Future<List<String>> listTables(String dbPath) async {
    if (listError != null) throw listError!;
    return allTables;
  }

  @override
  Future<ImportTableStream> exportTable(String dbPath, String table) async {
    if (exportError != null) throw exportError!;
    return ImportTableStream(
      table: table,
      rows: Stream.fromIterable(rowsByTable[table] ?? const []),
    );
  }
}

void main() {
  /// POSTs [body] to the import route and returns the `error.code` of a
  /// non-2xx answer, asserting the expected [statusCode].
  Future<String> expectError(
    HandlerHarness api,
    int statusCode,
    Map<String, Object?> body,
  ) async {
    final response = await api.send('POST', '/imports/gliderscore', body: body);
    expect(response.statusCode, statusCode);
    return (await api.errorOf(response))['code']! as String;
  }

  test('returns 201 with the full snapshot when the runner is wired', () async {
    final runner = FakeGliderScoreImportRunner(
      allTables: ['Scores', 'Pilots'],
      rowsByTable: {
        'Scores': [
          {'pilot': 'J. Smith', 'score': 12},
        ],
        'Pilots': [
          {'name': 'J. Smith'},
        ],
      },
    );
    final api = HandlerHarness(_owner, gliderScoreImport: runner);

    final response = await api.send(
      'POST',
      '/imports/gliderscore',
      body: {'path': _dbPath},
    );

    expect(response.statusCode, 201);
    final body = await api.json(response);
    expect(body['schema'], 'gs-import/v1');
    expect(body['sourceDbFile'], 'GliderScoreData.mdb');
    final tables = (body['tables'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect([for (final t in tables) t['name']], ['Scores', 'Pilots']);
    final scores =
        tables.singleWhere((t) => t['name'] == 'Scores')['rows']
            as List<Object?>;
    expect((scores.single as Map<Object?, Object?>)['pilot'], 'J. Smith');
  });

  test(
    'requested subset returns only those tables, in request order',
    () async {
      final runner = FakeGliderScoreImportRunner(
        allTables: ['Scores', 'Pilots', 'Comps'],
        rowsByTable: {
          'Scores': [{}],
          'Pilots': [{}],
          'Comps': [{}],
        },
      );
      final api = HandlerHarness(_owner, gliderScoreImport: runner);

      final response = await api.send(
        'POST',
        '/imports/gliderscore',
        body: {
          'path': _dbPath,
          'tables': ['Comps', 'Scores'],
        },
      );

      expect(response.statusCode, 201);
      final tables = ((await api.json(response))['tables']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect([for (final t in tables) t['name']], ['Comps', 'Scores']);
    },
  );

  test('a missing or blank path is a 400', () async {
    final api = HandlerHarness(
      _owner,
      gliderScoreImport: FakeGliderScoreImportRunner(),
    );
    for (final body in [
      <String, Object?>{},
      {'path': '   '},
    ]) {
      final response = await api.send(
        'POST',
        '/imports/gliderscore',
        body: body,
      );
      expect(response.statusCode, 400, reason: '$body');
    }
  });

  test('a path that is not a .mdb is a 415 import_unsupported', () async {
    final api = HandlerHarness(
      _owner,
      gliderScoreImport: FakeGliderScoreImportRunner(allTables: ['Scores']),
    );

    final response = await api.send(
      'POST',
      '/imports/gliderscore',
      body: {'path': 'C:\\data\\export.accdb'},
    );

    expect(response.statusCode, 415);
    expect((await api.errorOf(response))['code'], 'import_unsupported');
  });

  test('an unavailable runner is a 503 import_unavailable', () async {
    final api = HandlerHarness(
      _owner,
      gliderScoreImport: FakeGliderScoreImportRunner(available: false),
    );

    final response = await api.send(
      'POST',
      '/imports/gliderscore',
      body: {'path': _dbPath},
    );

    expect(response.statusCode, 503);
    expect((await api.errorOf(response))['code'], 'import_unavailable');
  });

  test('no runner wired (hosted server) is a 503 import_unavailable', () async {
    final api = HandlerHarness(_owner);

    final response = await api.send(
      'POST',
      '/imports/gliderscore',
      body: {'path': _dbPath},
    );

    expect(response.statusCode, 503);
    expect((await api.errorOf(response))['code'], 'import_unavailable');
  });

  test('a missing database is a 404 import_not_found', () async {
    final api = HandlerHarness(
      _owner,
      gliderScoreImport: FakeGliderScoreImportRunner(
        listError: ImportDatabaseNotFoundError('no database file at $_dbPath'),
      ),
    );

    expect(await expectError(api, 404, {'path': _dbPath}), 'import_not_found');
  });

  test('a corrupt database is a 422 import_corrupt', () async {
    final api = HandlerHarness(
      _owner,
      gliderScoreImport: FakeGliderScoreImportRunner(
        listError: ImportCorruptDatabaseError('mdb-tables exited 1'),
      ),
    );

    expect(await expectError(api, 422, {'path': _dbPath}), 'import_corrupt');
  });

  test('a malformed table is a 422 import_malformed', () async {
    final api = HandlerHarness(
      _owner,
      gliderScoreImport: FakeGliderScoreImportRunner(
        allTables: ['Scores'],
        exportError: ImportMalformedTableError('line 3 is not a JSON object'),
      ),
    );

    expect(await expectError(api, 422, {'path': _dbPath}), 'import_malformed');
  });

  test('a requested table that is not in the database is a 404', () async {
    final api = HandlerHarness(
      _owner,
      gliderScoreImport: FakeGliderScoreImportRunner(
        allTables: ['Scores'],
        rowsByTable: {
          'Scores': [{}],
        },
      ),
    );

    expect(
      await expectError(api, 404, {
        'path': _dbPath,
        'tables': ['Comps'],
      }),
      'import_table_not_found',
    );
  });
}
