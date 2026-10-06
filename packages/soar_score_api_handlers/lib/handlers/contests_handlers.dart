import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/handlers/write_metadata.dart';
import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Adds the contest routes to [router] (which is mounted under `/api/v1`):
///
/// - `GET /contests` and `GET /contests/{id}`
/// - `POST /contests` creates a contest owned by the request's principal
/// - `PUT /contests/{id}` replaces identity, schedule and location
/// - `POST /contests/{id}/actions` applies a director action
///
/// Writes act as the request's `Principal`: it owns what is created and is
/// the actor recorded with each change. The handlers only translate between
/// HTTP and [ContestsService].
void addContestRoutes(Router router, Repository repository) {
  final service = ContestsService(repository);

  router.get('/contests', (Request request) async {
    final contests = await service.getContests();

    return jsonResponse(<String, dynamic>{
      'contests': [for (final contest in contests) contest.toJson()],
    });
  });

  router.get('/contests/<id>', (Request request, String id) async {
    final contest = await service.getContest(Id.parse(id));
    return jsonResponse(contest.toJson());
  });

  router.post('/contests', (Request request) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, CreateContestRequest.fromJson);

    final contest = await service.createContest(
      NewContest(
        id: body.id,
        timezone: body.timezone,
        details: ContestDetails(
          name: body.name,
          startDateTime: body.startDateTime,
          endDateTime: body.endDateTime,
          host: body.host,
          city: body.city,
          state: body.state,
          country: body.country,
        ),
      ),
      ownerAccountId: principal.accountId,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(contest.toJson(), statusCode: 201);
  });

  router.put('/contests/<id>', (Request request, String id) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    final body = await readJsonBody(request, UpdateContestRequest.fromJson);

    final contest = await service.updateContest(
      contestId,
      ContestDetails(
        name: body.name,
        startDateTime: body.startDateTime,
        endDateTime: body.endDateTime,
        host: body.host,
        city: body.city,
        state: body.state,
        country: body.country,
      ),
      baseRevision: body.baseRevision,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(contest.toJson());
  });

  router.post('/contests/<id>/actions', (Request request, String id) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    final body = await readJsonBody(request, ContestActionRequest.fromJson);

    final contest = await service.applyAction(
      contestId,
      body.action,
      baseRevision: body.baseRevision,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(contest.toJson());
  });
}
