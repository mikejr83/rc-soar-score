import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../stubs/stub_contest_repository.dart';
import '../stubs/stub_repository.dart';

/// A handler over [StubRepository], acting as [principal], with helpers to
/// call it as the real server would be called.
class HandlerHarness {
  HandlerHarness(this.principal, {bool publishingEnabled = false})
    : contests = StubContestRepository() {
    repository = StubRepository(contests);
    handler = buildApiHandler(
      name: 'soar_score_server',
      displayName: 'Soar Score API Server',
      version: '0.1.0',
      repository: repository,
      authMiddleware: fixedPrincipal(Principal(accountId: principal)),
      publishingEnabled: publishingEnabled,
    );
  }

  final Id principal;
  final StubContestRepository contests;
  late final StubRepository repository;
  late final Handler handler;

  /// Sends [method] to `/api/v1[path]` with [body] as JSON.
  Future<Response> send(String method, String path, {Object? body}) async =>
      handler(
        Request(
          method,
          Uri.parse('http://localhost/api/v1$path'),
          body: body == null ? null : jsonEncode(body),
        ),
      );

  /// The JSON object in the body of [response].
  Future<Map<String, Object?>> json(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, Object?>;

  /// The `error` object of an error response.
  Future<Map<String, Object?>> errorOf(Response response) async =>
      (await json(response))['error'] as Map<String, Object?>;
}
