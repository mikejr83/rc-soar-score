import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_core/repositories/repository.dart';
import 'package:soar_score_api_handlers/handlers/configuration_handlers.dart';
import 'package:soar_score_api_handlers/handlers/contests_handlers.dart';
import 'package:soar_score_api_handlers/handlers/participants_handlers.dart';
import 'package:soar_score_api_handlers/handlers/participations_handlers.dart';
import 'package:soar_score_api_handlers/handlers/teams_handlers.dart';

({Handler healthHandler, Handler apiHandler}) createHandlers(
  String name,
  String displayName,
  String version,
  Repository repository,
) {
  final router = Router()
    ..get(
      '/ping',
      (Request request) => jsonResponse(<String, Object>{'status': 'ok'}),
    );
  addContestRoutes(router, repository);
  addConfigurationRoutes(router, repository);
  addParticipantRoutes(router, repository);
  addParticipationRoutes(router, repository);
  addTeamRoutes(router, repository);

  return (
    healthHandler: createHealthHandler(name, displayName, version, repository),
    apiHandler: router.call,
  );
}
