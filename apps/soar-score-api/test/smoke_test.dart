import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

void main() {
  test('API server smoke test: dependencies resolvable', () {
    expect(1 + 1, equals(2));
  });

  test('thin entrypoint wires a domain-backed server', () async {
    final server = ContestServer(repository: InMemoryContestRepository());
    final response = await server
        .handler(Request('GET', Uri.parse('http://localhost/health')));
    expect(response.statusCode, equals(200));
    final body = jsonDecode(await response.readAsString());
    expect(body['status'], equals('healthy'));
  });
}