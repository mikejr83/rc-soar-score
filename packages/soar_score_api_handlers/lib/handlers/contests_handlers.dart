import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/contest_authorization.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/handlers/write_metadata.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _logger = Logger('Contests');

/// Adds the contest routes to [router] (which is mounted under `/api/v1`):
///
/// - `GET /contests` and `GET /contests/{id}`
/// - `POST /contests` creates a contest owned by the request's principal
/// - `PUT /contests/{id}` replaces identity, schedule and location
/// - `POST /contests/{id}/actions` applies a director action
/// - `GET /contests/{id}/audit-events` lists the contest's audit events,
///   newest first (`action` and `limit` narrow them)
///
/// Writes act as the request's `Principal`: it owns what is created and is
/// the actor recorded with each change. The handlers only translate between
/// HTTP and [ContestsService].
void addContestRoutes(
  Router router,
  Repository repository, {
  bool publishingEnabled = false,
}) {
  final service = ContestsService(repository);
  final publicUpdates = PublicUpdateService(repository);

  router.get('/contests', (Request request) async {
    final principal = requirePrincipal(request);
    final contests = await service.getContests();

    return jsonResponse(<String, dynamic>{
      'contests': [
        for (final contest in contests)
          if (contest.ownerAccountId == principal.accountId ||
              principal.alsoVisibleOwners.contains(contest.ownerAccountId))
            contest.toJson(),
      ],
    });
  });

  router.get('/contests/<id>', (Request request, String id) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final contest = await service.getContest(contestId);
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
    await requireContestDirector(request, repository, contestId);
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
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, ContestActionRequest.fromJson);

    final contest = await service.applyAction(
      contestId,
      body.action,
      baseRevision: body.baseRevision,
      metadata: writeMetadata(principal),
    );
    if (publishingEnabled && body.action == ContestAction.complete) {
      // The public site shows the contest as Completed once it republishes.
      // The contest is completed whatever happens here.
      try {
        await publicUpdates.afterCompletion(
          contestId,
          revision: contest.revision,
        );
      } on Object catch (error, stackTrace) {
        _logger.warning(
          'Public update after completing contest $id failed; the last '
          'projection stays public',
          error,
          stackTrace,
        );
      }
    }
    return jsonResponse(contest.toJson());
  });
  router.get('/contests/<id>/audit-events', (Request request, String id) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final query = request.url.queryParameters;

    final actionText = query['action'];
    final action = actionText == null
        ? null
        : AuditActionText.parse(actionText);
    if (actionText != null && action == null) {
      throw ArgumentError.value(actionText, 'action', 'not an audit action');
    }
    final limitText = query['limit'];
    final limit = limitText == null ? null : int.tryParse(limitText);
    if (limitText != null && limit == null) {
      throw ArgumentError.value(limitText, 'limit', 'not a whole number');
    }

    final events = await service.auditEvents(
      contestId,
      action: action,
      limit: limit,
    );
    return jsonResponse(<String, dynamic>{
      'audit_events': [
        for (final event in events) AuditEventDto.fromEvent(event).toJson(),
      ],
    });
  });
}
