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
  final contestId = Id.parse('019c0000-0000-7000-8000-000000000020');
  final teamId = Id.parse('019c0000-0000-7000-8000-000000000301');
  final membershipId = Id.parse('019c0000-0000-7000-8000-000000000401');
  final participationId = Id.parse('019c0000-0000-7000-8000-000000000201');
  final team = Team(id: teamId, contestId: contestId, name: 'Team Red');
  final membership = TeamMembership(
    id: membershipId,
    teamId: teamId,
    contestParticipationId: participationId,
    contestId: contestId,
  );
  final contestPath = '/api/v1/contests/${contestId.value}';

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

  test('teams(id) reads the list', () async {
    final client = clientFor(
      (_) => body({
        'teams': [team.toJson()],
      }),
    );

    expect(await client.teams(contestId), [team]);
    expect(seen.method, 'GET');
    expect(seen.url.path, '$contestPath/teams');
  });

  test('createTeam POSTs the request', () async {
    final client = clientFor((_) => body(team.toJson(), 201));
    final request = CreateTeamRequest(id: teamId, name: 'Team Red');

    expect(await client.createTeam(contestId, request), team);
    expect(seen.method, 'POST');
    expect(seen.url.path, '$contestPath/teams');
    expect(jsonDecode(seen.body), request.toJson());
  });

  test('updateTeam PUTs the new name', () async {
    final client = clientFor((_) => body(team.toJson()));
    const request = UpdateTeamRequest(baseRevision: 0, name: 'Team Red');

    await client.updateTeam(contestId, teamId, request);

    expect(seen.method, 'PUT');
    expect(seen.url.path, '$contestPath/teams/${teamId.value}');
    expect(jsonDecode(seen.body), request.toJson());
  });

  test('deleteTeam sends DELETE', () async {
    final client = clientFor((_) => http.Response('', 204));

    await client.deleteTeam(contestId, teamId);

    expect(seen.method, 'DELETE');
    expect(seen.url.path, '$contestPath/teams/${teamId.value}');
  });

  test('teamMemberships reads the list', () async {
    final client = clientFor(
      (_) => body({
        'team_memberships': [membership.toJson()],
      }),
    );

    expect(await client.teamMemberships(contestId), [membership]);
    expect(seen.url.path, '$contestPath/team-memberships');
  });

  test('addTeamMember POSTs the request', () async {
    final client = clientFor((_) => body(membership.toJson(), 201));
    final request = AddTeamMemberRequest(
      id: membershipId,
      teamId: teamId,
      contestParticipationId: participationId,
    );

    expect(await client.addTeamMember(contestId, request), membership);
    expect(seen.method, 'POST');
    expect(seen.url.path, '$contestPath/team-memberships');
    expect(jsonDecode(seen.body), request.toJson());
  });

  test('removeTeamMember sends DELETE', () async {
    final client = clientFor((_) => http.Response('', 204));

    await client.removeTeamMember(contestId, membershipId);

    expect(seen.method, 'DELETE');
    expect(
      seen.url.path,
      '$contestPath/team-memberships/${membershipId.value}',
    );
  });
}
