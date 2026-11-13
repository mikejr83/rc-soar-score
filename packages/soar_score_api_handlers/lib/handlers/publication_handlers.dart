import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/contest_authorization.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// How long a refused publish request may take to deliver its body, so the
/// attempt can still be audited. A slower caller gets the 403 without it.
const _deniedBodyWait = Duration(seconds: 2);

/// The publication routes (all inside `/api/v1`, for the contest's director):
///
/// - `POST /contests/{id}/publication` publishes the contest (201). The first
///   publish creates an Unlisted publication; later ones add the next
///   projection. Repeating a `client_mutation_id` returns the first result
///   (200);
/// - `GET /contests/{id}/publication` is the director's view of it;
/// - `PATCH /contests/{id}/publication/visibility` switches between
///   `Unlisted` and `Public`;
/// - `GET /contests/{id}/publication/projections` lists the projections,
///   newest first (`limit` up to 100, default 50, and `offset`);
/// - `POST /contests/{id}/publication/delist-requests` asks to delist the
///   publication (201; 200 with the pending request when one is already
///   pending);
/// - `GET /contests/{id}/publication/delist-requests/current` is the latest
///   request, any state (404 when there is none);
/// - `DELETE /contests/{id}/publication/delist-requests/current` withdraws
///   the pending request (404 when none is pending).
///
/// The administrator's approve or deny flow plugs in beside the last two.
///
/// Publishing exists only on the hosted server. With [enabled] false (the
/// embedded server) every route answers 409 `publishing_not_available`, so a
/// contest kept on one machine never publishes by accident.
///
/// The handlers only translate between HTTP and [PublicationService].
void addPublicationRoutes(
  Router router,
  Repository repository, {
  required bool enabled,
}) {
  final service = PublicationService(repository);
  final delisting = DelistRequestService(repository);

  Principal available(Request request) {
    final principal = requirePrincipal(request);
    if (!enabled) {
      throw ContestStateError(
        'publishing_not_available',
        'this server does not publish contests',
      );
    }
    return principal;
  }

  router.post('/contests/<id>/publication', (Request request, String id) async {
    final principal = available(request);
    try {
      await requireContestDirector(request, repository, Id.parse(id));
    } on ForbiddenError {
      // The refusal is audited: a well-formed attempt by someone who is not
      // the director is recorded by the service, which refuses it. The body
      // is only waited for briefly ([_deniedBodyWait]); one that is slow,
      // cannot be read, or any other failure, leaves the plain 403.
      try {
        final attempt = await readJsonBody(
          request,
          PublishContestRequest.fromJson,
        ).timeout(_deniedBodyWait);
        await service.publish(
          Id.parse(id),
          actorId: principal.accountId,
          authority: principal.authority,
          clientMutationId: attempt.clientMutationId,
          sourceContestRevision: attempt.sourceContestRevision,
        );
      } on Object {
        // Falls through to the refusal below.
      }
      rethrow;
    }
    final body = await readJsonBody(request, PublishContestRequest.fromJson);
    final result = await service.publish(
      Id.parse(id),
      actorId: principal.accountId,
      authority: principal.authority,
      clientMutationId: body.clientMutationId,
      sourceContestRevision: body.sourceContestRevision,
    );
    return jsonResponse(
      result.view.toJson(),
      statusCode: result.created ? 201 : 200,
    );
  });

  router.get('/contests/<id>/publication', (Request request, String id) async {
    final principal = available(request);
    final view = await service.read(
      Id.parse(id),
      actorId: principal.accountId,
      authority: principal.authority,
    );
    return jsonResponse(view.toJson());
  });

  router.patch('/contests/<id>/publication/visibility', (
    Request request,
    String id,
  ) async {
    final principal = available(request);
    await requireContestDirector(request, repository, Id.parse(id));
    final body = await readJsonBody(request, SetVisibilityRequest.fromJson);
    final visibility = switch (body.visibility) {
      'Unlisted' => PublicationVisibility.unlisted,
      'Public' => PublicationVisibility.public,
      _ => throw ArgumentError('visibility must be Unlisted or Public'),
    };
    final view = await service.setVisibility(
      Id.parse(id),
      visibility,
      actorId: principal.accountId,
      authority: principal.authority,
    );
    return jsonResponse(view.toJson());
  });

  router.get('/contests/<id>/publication/projections', (
    Request request,
    String id,
  ) async {
    final principal = available(request);
    final query = request.url.queryParameters;
    final limit = _intParameter(query, 'limit') ?? 50;
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', 'must be 1 to 100');
    }
    final offset = _intParameter(query, 'offset') ?? 0;
    final entries = await service.history(
      Id.parse(id),
      actorId: principal.accountId,
      authority: principal.authority,
      limit: limit,
      offset: offset,
    );
    return jsonResponse({
      'projections': [
        for (final entry in entries)
          PublicationHistoryEntryDto(
            id: entry.projection.id,
            projectionRevision: entry.projection.projectionRevision,
            contestRevision: entry.projection.contestRevision,
            publishedAt: entry.projection.publishedAt,
            publishedBy: entry.projection.publishedBy,
            publisherKind: entry.bySystem ? 'system' : 'person',
          ).toJson(),
      ],
    });
  });

  router.post('/contests/<id>/publication/delist-requests', (
    Request request,
    String id,
  ) async {
    final principal = available(request);
    await requireContestDirector(request, repository, Id.parse(id));
    final body = await readJsonBody(request, RequestDelistingRequest.fromJson);
    final result = await delisting.request(
      Id.parse(id),
      actorId: principal.accountId,
      authority: principal.authority,
      reason: body.reason,
    );
    return jsonResponse(
      result.request.toJson(),
      statusCode: result.created ? 201 : 200,
    );
  });

  router.get('/contests/<id>/publication/delist-requests/current', (
    Request request,
    String id,
  ) async {
    final principal = available(request);
    final found = await delisting.current(
      Id.parse(id),
      actorId: principal.accountId,
      authority: principal.authority,
    );
    return jsonResponse(found.toJson());
  });

  router.delete('/contests/<id>/publication/delist-requests/current', (
    Request request,
    String id,
  ) async {
    final principal = available(request);
    final withdrawn = await delisting.withdraw(
      Id.parse(id),
      actorId: principal.accountId,
      authority: principal.authority,
    );
    return jsonResponse(withdrawn.toJson());
  });
}

int? _intParameter(Map<String, String> query, String name) {
  final raw = query[name];
  if (raw == null) return null;
  return int.tryParse(raw) ??
      (throw ArgumentError.value(raw, name, 'not a whole number'));
}
