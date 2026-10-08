import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final baseUrl = Uri.parse('http://localhost:8085');
  const jsonHeaders = <String, String>{
    'content-type': 'application/json; charset=utf-8',
  };
  final tableId = Id.parse('019c0000-0000-7000-8000-000000000301');
  final view = LandingTableView(
    content: LandingTableWithResults(
      table: LandingTable(
        id: tableId,
        ownerAccountId: Id.parse('019c0000-0000-7000-8000-000000000001'),
        name: 'Club table',
        inputUnit: LandingInputUnit.feet,
        createdAt: DateTime.utc(2026, 10),
      ),
      results: [
        LandingResult(
          id: Id.parse('019c0000-0000-7000-8000-000000000401'),
          landingTableId: tableId,
          entryKey: 'close',
          displayValue: 'Close',
          pointValue: 10,
          ordinalPosition: 1,
        ),
      ],
    ),
    inUse: true,
  );

  late http.Request seen;

  ApiClient clientFor(http.Response Function(http.Request) respond) {
    final client = ApiClient(
      baseUrl: baseUrl,
      httpClient: MockClient((request) async {
        seen = request;
        return respond(request);
      }),
    );
    addTearDown(client.close);
    return client;
  }

  http.Response body(Object json, [int status = 200]) =>
      http.Response(jsonEncode(json), status, headers: jsonHeaders);

  test('landingTables() reads the tables with their in-use flag', () async {
    final client = clientFor(
      (_) => body({
        'landing_tables': [view.toJson()],
      }),
    );

    expect(await client.landingTables(), [view]);
    expect(seen.method, 'GET');
    expect(seen.url.path, '/api/v1/landing-tables');
  });

  test('createLandingTable posts the entries in order', () async {
    final client = clientFor((_) => body(view.toJson(), 201));

    final created = await client.createLandingTable(
      CreateLandingTableRequest(
        id: tableId,
        name: 'Club table',
        inputUnit: LandingInputUnit.feet,
        entries: const [
          LandingEntryInput(
            entryKey: 'close',
            displayValue: '',
            pointValue: 10,
          ),
        ],
      ),
    );

    expect(created, view);
    expect(seen.method, 'POST');
    expect(jsonDecode(seen.body), {
      'id': tableId.value,
      'name': 'Club table',
      'input_unit': 'feet',
      'entries': [
        {'entry_key': 'close', 'display_value': '', 'point_value': 10},
      ],
    });
  });

  test('deleteLandingTable sends DELETE and accepts 204', () async {
    final client = clientFor((_) => http.Response('', 204));

    await client.deleteLandingTable(tableId);

    expect(seen.method, 'DELETE');
    expect(seen.url.path, '/api/v1/landing-tables/${tableId.value}');
  });

  test('a table in use is an ApiHttpError with status 409', () async {
    final client = clientFor(
      (_) => body({
        'error': {'code': 'in_use', 'message': 'used by a contest'},
      }, 409),
    );

    await expectLater(
      client.deleteLandingTable(tableId),
      throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 409)),
    );
  });
}
