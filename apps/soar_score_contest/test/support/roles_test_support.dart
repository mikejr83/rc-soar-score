import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/roles_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_core/services/role_usage.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'participant_test_support.dart';

/// A role the director added, with a fixed id from [n].
Role ownRole(String name, {int n = 50, int revision = 0}) => Role(
  id: Id.parse('019c0000-0000-7000-8000-0000000003$n'),
  ownerAccountId: Id.parse(ownerId),
  displayName: name,
  type: RoleType.nonFlier,
  revision: revision,
);

/// An in-memory roles API: answers the role routes from [roles] and
/// [usage], applies create, rename and delete to [roles], and records every
/// request. A route in [failures] answers with that status and message.
class FakeRolesApi {
  FakeRolesApi({List<Role>? roles, Map<Id, List<RoleUsage>>? usage})
    : roles = roles ?? [...SystemRoles.all],
      usage = usage ?? {};

  final List<Role> roles;
  final Map<Id, List<RoleUsage>> usage;
  final List<http.Request> requests = [];

  /// `METHOD /path` to the error answered instead.
  final Map<String, ({int status, String code, String message})> failures = {};

  ApiClient get client => clientFor(_respond, requests: requests);

  Future<http.Response> _respond(http.Request request) async {
    final path = request.url.path.replaceFirst('/api/v1', '');
    final failure = failures['${request.method} $path'];
    if (failure != null) {
      return errorResponse(failure.status, failure.code, failure.message);
    }
    final body = request.body.isEmpty
        ? null
        : jsonDecode(request.body) as Map<String, dynamic>;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (request.method == 'GET' && path == '/roles') {
      return json({
        'roles': [for (final role in roles) role.toJson()],
      });
    }
    if (request.method == 'POST' && path == '/roles') {
      final role = Role(
        id: Id.parse(body!['id'] as String),
        ownerAccountId: Id.parse(ownerId),
        displayName: body['display_name'] as String,
        type: RoleType.nonFlier,
      );
      roles.add(role);
      return json(role.toJson(), 201);
    }
    final id = Id.parse(segments[1]);
    if (request.method == 'GET' && segments.length == 3) {
      return json({
        'usage': [for (final item in usage[id] ?? <RoleUsage>[]) item.toJson()],
      });
    }
    final index = roles.indexWhere((role) => role.id == id);
    if (request.method == 'PUT') {
      final renamed = Role(
        id: id,
        ownerAccountId: Id.parse(ownerId),
        displayName: body!['display_name'] as String,
        type: RoleType.nonFlier,
        revision: roles[index].revision + 1,
      );
      roles[index] = renamed;
      return json(renamed.toJson());
    }
    roles.removeAt(index);
    return http.Response('', 204);
  }
}

/// Usage of a role in one contest.
RoleUsage usedIn(String contest, int count, {int n = 1}) => RoleUsage(
  contestId: Id.parse(
    '019c0000-0000-7000-8000-0000000004${n.toString().padLeft(2, '0')}',
  ),
  contestName: contest,
  participantCount: count,
);

/// The roles route (as the real router builds it) under [client].
Widget rolesApp(ApiClient client, {String initial = rolesPath}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: rolesPath,
        builder: (_, state) => Scaffold(
          body: RolesPage(
            createRequested: state.uri.queryParameters['new'] == '1',
          ),
        ),
      ),
    ],
  );
  return ApiClientInherited(
    client: client,
    child: MaterialApp.router(routerConfig: router),
  );
}
