import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryContestRepository repository;
  late ContestServer server;
  late Handler handler;

  setUp(() {
    repository = InMemoryContestRepository();
    server = ContestServer(repository: repository);
    handler = server.handler;
  });

  Future<Map<String, dynamic>> send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = Request(
      method,
      Uri.parse('http://localhost$path'),
      body: jsonEncode(body ?? const {}),
      headers: const {'content-type': 'application/json'},
    );
    final response = await handler(request);
    return jsonDecode(await response.readAsString());
  }

  Future<Response> get(String path) async {
    return handler(Request('GET', Uri.parse('http://localhost$path')));
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await get(path);
    return jsonDecode(await response.readAsString());
  }

  test('GET /health returns healthy status', () async {
    final response = await get('/health');
    expect(response.statusCode, equals(200));
    final body = await getJson('/health');
    expect(body['status'], equals('healthy'));
  });

  test('GET /api/contests returns empty list initially', () async {
    final body = await getJson('/api/contests');
    expect(body['contests'], isEmpty);
  });

  test('POST /api/contests creates and returns a contest', () async {
    final body = await send('POST', '/api/contests', body: {
      'name': 'Test Contest',
      'startDate': '2026-01-01T00:00:00Z',
      'endDate': '2026-01-02T00:00:00Z',
      'hostVenue': 'Test Venue',
    });
    expect(body['contest']['name'], equals('Test Contest'));
    expect(body['contest']['id'], isNotNull);

    final listed = await getJson('/api/contests');
    expect(listed['contests'], hasLength(1));
  });

  test('GET /api/contests/<id> returns 404 for unknown id', () async {
    final response = await get('/api/contests/does-not-exist');
    expect(response.statusCode, equals(404));
  });

  test('PUT /api/contests/<id> updates an existing contest', () async {
    final created = await send('POST', '/api/contests', body: {'name': 'Original'});
    final id = created['contest']['id'] as String;

    final updated = await send('PUT', '/api/contests/$id', body: {'name': 'Renamed'});
    expect(updated['contest']['name'], equals('Renamed'));
    expect(updated['contest']['id'], equals(id));
  });

  test('DELETE /api/contests/<id> removes a contest', () async {
    final created = await send('POST', '/api/contests', body: {'name': 'To Delete'});
    final id = created['contest']['id'] as String;

    final request = Request(
      'DELETE',
      Uri.parse('http://localhost/api/contests/$id'),
    );
    final response = await handler(request);
    expect(response.statusCode, equals(204));
  });

  test('server is backed by the domain Contest model', () async {
    // Ensures the repository stores a real Contest, not a raw map.
    await repository.saveContest(Contest(
      id: 'c1',
      name: 'Domain',
      startDate: DateTime(2026),
      endDate: DateTime(2026),
      hostVenue: 'V',
      createdAt: DateTime(2026),
      lastModifiedAt: DateTime(2026),
    ));
    final fetched = await repository.getContest('c1');
    expect(fetched, isA<Contest>());
    expect(fetched!.name, equals('Domain'));
  });
}