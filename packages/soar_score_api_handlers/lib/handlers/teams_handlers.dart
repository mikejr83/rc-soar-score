import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/contest_authorization.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/handlers/write_metadata.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Adds the team routes to [router] (which is mounted under `/api/v1`):
///
/// - `GET /contests/{id}/teams` and `POST /contests/{id}/teams`
/// - `PUT /contests/{id}/teams/{teamId}` renames a team
/// - `DELETE /contests/{id}/teams/{teamId}` deletes it with its memberships
/// - `GET /contests/{id}/team-memberships` and
///   `POST /contests/{id}/team-memberships` put a participant on a team
/// - `DELETE /contests/{id}/team-memberships/{membershipId}` takes them off
///
/// The handlers only translate between HTTP and [TeamsService].
void addTeamRoutes(Router router, Repository repository) {
  final service = TeamsService(repository);

  router.get('/contests/<id>/teams', (Request request, String id) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final teams = await service.listTeams(contestId);
    return jsonResponse(<String, dynamic>{
      'teams': [for (final team in teams) team.toJson()],
    });
  });

  router.post('/contests/<id>/teams', (Request request, String id) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, CreateTeamRequest.fromJson);

    final team = await service.createTeam(
      contestId,
      id: body.id,
      name: body.name,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(team.toJson(), statusCode: 201);
  });

  router.put('/contests/<id>/teams/<teamId>', (
    Request request,
    String id,
    String teamId,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, UpdateTeamRequest.fromJson);

    final team = await service.renameTeam(
      contestId,
      Id.parse(teamId),
      name: body.name,
      baseRevision: body.baseRevision,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(team.toJson());
  });

  router.delete('/contests/<id>/teams/<teamId>', (
    Request request,
    String id,
    String teamId,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    await service.deleteTeam(
      contestId,
      Id.parse(teamId),
      metadata: writeMetadata(principal),
    );
    return Response(204);
  });

  router.get('/contests/<id>/team-memberships', (
    Request request,
    String id,
  ) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final memberships = await service.listMemberships(contestId);
    return jsonResponse(<String, dynamic>{
      'team_memberships': [
        for (final membership in memberships) membership.toJson(),
      ],
    });
  });

  router.post('/contests/<id>/team-memberships', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, AddTeamMemberRequest.fromJson);

    final membership = await service.addMember(
      contestId,
      id: body.id,
      teamId: body.teamId,
      participationId: body.contestParticipationId,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(membership.toJson(), statusCode: 201);
  });

  router.delete('/contests/<id>/team-memberships/<membershipId>', (
    Request request,
    String id,
    String membershipId,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    await service.removeMember(
      contestId,
      Id.parse(membershipId),
      metadata: writeMetadata(principal),
    );
    return Response(204);
  });
}
