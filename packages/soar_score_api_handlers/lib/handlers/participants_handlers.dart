import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/handlers/write_metadata.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Adds the participant routes to [router] (which is mounted under
/// `/api/v1`):
///
/// - `GET /participants` and `GET /participants/{id}` read the caller's
///   profiles
/// - `POST /participants` creates a profile owned by the request's principal
/// - `PUT /participants/{id}` replaces its details
/// - `DELETE /participants/{id}` deletes a profile that is in no contest
///
/// A profile belongs to the principal that created it; another principal's
/// profile is answered as not found. The handlers only translate between
/// HTTP and [ParticipantsService].
void addParticipantRoutes(Router router, Repository repository) {
  final service = ParticipantsService(repository);

  router.get('/participants', (Request request) async {
    final principal = requirePrincipal(request);
    final profiles = await service.list(principal.accountId);
    return jsonResponse(<String, dynamic>{
      'participants': [for (final profile in profiles) profile.toJson()],
    });
  });

  router.get('/participants/<id>', (Request request, String id) async {
    final principal = requirePrincipal(request);
    final profile = await service.get(principal.accountId, Id.parse(id));
    return jsonResponse(profile.toJson());
  });

  router.post('/participants', (Request request) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, CreateParticipantRequest.fromJson);

    final profile = await service.create(
      principal.accountId,
      body.id,
      ParticipantDetails(
        firstName: body.firstName,
        lastName: body.lastName,
        club: body.club,
        faiNumber: body.faiNumber,
        nationalOrgId: body.nationalOrgId,
        city: body.city,
        state: body.state,
        country: body.country,
        email: body.email,
      ),
      metadata: writeMetadata(principal),
    );
    return jsonResponse(profile.toJson(), statusCode: 201);
  });

  router.put('/participants/<id>', (Request request, String id) async {
    final principal = requirePrincipal(request);
    final profileId = Id.parse(id);
    final body = await readJsonBody(request, UpdateParticipantRequest.fromJson);

    final profile = await service.update(
      principal.accountId,
      profileId,
      ParticipantDetails(
        firstName: body.firstName,
        lastName: body.lastName,
        club: body.club,
        faiNumber: body.faiNumber,
        nationalOrgId: body.nationalOrgId,
        city: body.city,
        state: body.state,
        country: body.country,
        email: body.email,
      ),
      baseRevision: body.baseRevision,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(profile.toJson());
  });

  router.delete('/participants/<id>', (Request request, String id) async {
    final principal = requirePrincipal(request);
    await service.delete(
      principal.accountId,
      Id.parse(id),
      metadata: writeMetadata(principal),
    );
    return Response(204);
  });
}
