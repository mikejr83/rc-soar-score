import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_core/repositories/repository.dart';
import 'package:soar_score_core/services/sync/sync_versions.dart';
import 'package:soar_score_api_handlers/handlers/account_claim_handlers.dart';
import 'package:soar_score_api_handlers/handlers/configuration_handlers.dart';
import 'package:soar_score_api_handlers/handlers/contests_handlers.dart';
import 'package:soar_score_api_handlers/handlers/landing_table_handlers.dart';
import 'package:soar_score_api_handlers/handlers/matrix_handlers.dart';
import 'package:soar_score_api_handlers/handlers/participants_handlers.dart';
import 'package:soar_score_api_handlers/handlers/participations_handlers.dart';
import 'package:soar_score_api_handlers/handlers/roles_handlers.dart';
import 'package:soar_score_api_handlers/handlers/public_publication_handlers.dart';
import 'package:soar_score_api_handlers/handlers/publication_handlers.dart';
import 'package:soar_score_api_handlers/handlers/results_handlers.dart';
import 'package:soar_score_api_handlers/handlers/scores_handlers.dart';
import 'package:soar_score_api_handlers/handlers/sync_handlers.dart';
import 'package:soar_score_api_handlers/handlers/teams_handlers.dart';
import 'package:soar_score_core/services/recalculation/recalculation_service.dart';

({Handler healthHandler, Handler apiHandler, Handler publicHandler})
createHandlers(
  String name,
  String displayName,
  String version,
  Repository repository, {
  bool publishingEnabled = false,
  RecalculationService? recalculation,
  SyncVersions? syncVersions,
}) {
  final router = Router()
    ..get(
      '/ping',
      (Request request) => jsonResponse(<String, Object>{'status': 'ok'}),
    );
  addAccountClaimRoutes(router, repository);
  addContestRoutes(router, repository);
  addConfigurationRoutes(router, repository);
  addLandingTableRoutes(router, repository);
  addParticipantRoutes(router, repository);
  addRoleRoutes(router, repository);
  addParticipationRoutes(router, repository);
  addTeamRoutes(router, repository);
  addMatrixRoutes(router, repository);
  addScoreRoutes(
    router,
    repository,
    publishingEnabled: publishingEnabled,
    recalculation: recalculation,
  );
  addResultsRoutes(router, repository);
  addPublicationRoutes(router, repository, enabled: publishingEnabled);
  addSyncRoutes(
    router,
    repository,
    versions: syncVersions ?? const SyncVersions.exactly(1),
  );

  return (
    healthHandler: createHealthHandler(name, displayName, version, repository),
    apiHandler: router.call,
    publicHandler: buildPublicHandler(repository, enabled: publishingEnabled),
  );
}
