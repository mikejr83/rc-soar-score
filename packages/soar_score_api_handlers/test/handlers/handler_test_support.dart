import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../stubs/stub_contest_repository.dart';
import '../stubs/stub_repository.dart';

/// A handler over [StubRepository], acting as [principal], with helpers to
/// call it as the real server would be called.
class HandlerHarness {
  HandlerHarness(
    this.principal, {
    bool publishingEnabled = false,
    RecalculationService? recalculation,
    GliderScoreImportRunner? gliderScoreImport,
    DrawRunner? drawRunner,
    Set<Id> alsoVisibleOwners = const {},
    StubContestRepository? contests,
  }) : contests = contests ?? StubContestRepository() {
    repository = StubRepository(this.contests);
    handler = buildApiHandler(
      name: 'soar_score_server',
      displayName: 'Soar Score API Server',
      version: '0.1.0',
      repository: repository,
      authMiddleware: fixedPrincipal(
        Principal(accountId: principal, alsoVisibleOwners: alsoVisibleOwners),
      ),
      publishingEnabled: publishingEnabled,
      recalculation: recalculation,
      gliderScoreImport: gliderScoreImport,
      drawRunner: drawRunner,
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

/// Two handler stacks over the same [StubContestRepository], one acting as
/// the owner of the test state and one as a foreign account.
class TwoAccountApi {
  TwoAccountApi({
    Id? owner,
    Id? outsider,
    Set<Id> alsoVisibleOwners = const {},
    RecalculationService? recalculation,
  }) : this._(
         owner ?? _defaultOwner,
         outsider ?? _defaultOutsider,
         alsoVisibleOwners,
         recalculation,
       );

  TwoAccountApi._(
    this.owner,
    this.outsider,
    Set<Id> alsoVisibleOwners,
    RecalculationService? recalculation,
  ) {
    final store = StubContestRepository();
    ownerApi = HandlerHarness(
      owner,
      contests: store,
      alsoVisibleOwners: alsoVisibleOwners,
      recalculation: recalculation,
    );
    outsiderApi = HandlerHarness(outsider, contests: store);
  }

  /// The account of the owner.
  final Id owner;

  /// The account of the foreign actor.
  final Id outsider;

  /// Acting as [owner].
  late final HandlerHarness ownerApi;

  /// Acting as [outsider].
  late final HandlerHarness outsiderApi;

  /// The shared contest store, for arrangements the API cannot reach.
  StubContestRepository get contests => ownerApi.contests;

  /// Stores a contest owned by [ownerAccountId] (default: [owner]) as [id].
  void storeContest(Id id, {Id? ownerAccountId}) {
    contests.replace(
      Contest(
        id: id,
        name: 'Summer Open',
        startDateTime: DateTime.utc(2026, 10, 17, 14),
        endDateTime: DateTime.utc(2026, 10, 18, 22),
        timezone: 'America/Denver',
        ownerAccountId: ownerAccountId ?? owner,
        createdAt: DateTime.utc(2026, 9),
        updatedAt: DateTime.utc(2026, 9),
      ),
    );
  }

  /// Calls [method] [path] on [api] and expects the 403 `not_director`.
  Future<void> expectDenied(
    HandlerHarness api,
    String method,
    String path, {
    Object? body,
  }) async {
    final response = await api.send(method, path, body: body);
    final error = await api.errorOf(response);
    expect(response.statusCode, 403, reason: '$error');
    expect(error['code'], 'not_director');
  }
}

final _defaultOwner = Id.parse('019c0000-0000-7000-8000-000000000001');
final _defaultOutsider = Id.parse('019c0000-0000-7000-8000-000000000002');
