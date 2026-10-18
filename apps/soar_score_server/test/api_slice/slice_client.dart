import 'dart:convert';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

/// The database an API slice test runs on.
enum SliceBackend { sqlite, postgres }

/// The deployed server's handler over a fresh database, called the way a
/// client would call it: JSON over `/api/v1` and `/public`, no socket.
///
/// Both backends use the server profile, so the backend-only publication
/// tables exist. Every request acts as [director], whose account is stored
/// first because publishing needs its profile.
class SliceClient {
  SliceClient._(this.database, this.director, this._handler, this._drop);

  static Future<SliceClient> open(SliceBackend backend) async {
    final director = core.Id.create();
    final SoarScoreDatabase database;
    Future<void> Function()? drop;
    switch (backend) {
      case SliceBackend.sqlite:
        database = SoarScoreDatabase(
          NativeDatabase.memory(),
          profile: DatabaseProfile.server,
        );
      case SliceBackend.postgres:
        final config = PostgresConfig.fromEnvironment()!;
        final name =
            'soar_slice_${DateTime.now().microsecondsSinceEpoch}_'
            '${Random().nextInt(1 << 30)}';
        final admin = await pg.Connection.open(
          config.named('postgres').toEndpoint(),
          settings: config.toSettings(),
        );
        await admin.execute('CREATE DATABASE "$name"');
        database = SoarScoreDatabase(
          config.named(name).toPgDatabase(),
          profile: DatabaseProfile.server,
        );
        drop = () async {
          await admin.execute('DROP DATABASE "$name" WITH (FORCE)');
          await admin.close();
        };
    }
    await SystemDataSeeder(database).seed();
    final now = DateTime.utc(2026, 10, 17, 15);
    await Repository(database).accountRepository.save(
      core.Account(
        id: director,
        firstName: 'Dana',
        lastName: 'Director',
        kind: core.AccountKind.registered,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final handler = createServerHandler(
      database,
      authMiddleware: fixedPrincipal(Principal(accountId: director)),
    );
    return SliceClient._(database, director, handler, drop);
  }

  final SoarScoreDatabase database;
  final core.Id director;
  final Handler _handler;
  final Future<void> Function()? _drop;

  Future<void> close() async {
    await database.close();
    await _drop?.call();
  }

  /// Sends [method] to `/api/v1[path]` and returns the status and JSON body.
  Future<SliceResponse> send(String method, String path, {Object? body}) =>
      _call(method, '/api/v1$path', body);

  /// Reads `/public[path]`, as an anonymous visitor does.
  Future<SliceResponse> publicGet(String path) =>
      _call('GET', '/public$path', null);

  Future<SliceResponse> _call(String method, String path, Object? body) async {
    final response = await _handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    final text = await response.readAsString();
    return SliceResponse(
      response.statusCode,
      text.isEmpty
          ? <String, Object?>{}
          : jsonDecode(text) as Map<String, Object?>,
    );
  }

  /// Sends a request that must succeed with [status] and returns its body.
  Future<Map<String, Object?>> expectOk(
    String method,
    String path, {
    Object? body,
    int status = 200,
  }) async {
    final response = await send(method, path, body: body);
    expect(response.status, status, reason: '$method $path: ${response.body}');
    return response.body;
  }
}

class SliceResponse {
  const SliceResponse(this.status, this.body);

  final int status;
  final Map<String, Object?> body;
}
