import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/draw/isolate_draw_runner.dart';
import 'package:soar_score_core/repositories/repository.dart';
import 'package:soar_score_core/services/matrix/draw_job.dart';
import 'package:soar_score_core/services/sync/sync_versions.dart';
import 'package:soar_score_api_handlers/handlers/account_claim_handlers.dart';
import 'package:soar_score_api_handlers/handlers/account_preferences_handlers.dart';
import 'package:soar_score_api_handlers/handlers/configuration_handlers.dart';
import 'package:soar_score_api_handlers/handlers/contests_handlers.dart';
import 'package:soar_score_api_handlers/handlers/landing_table_handlers.dart';
import 'package:soar_score_api_handlers/handlers/matrix_handlers.dart';
import 'package:soar_score_api_handlers/handlers/models_handlers.dart';
import 'package:soar_score_api_handlers/handlers/invitation_handlers.dart';
import 'package:soar_score_api_handlers/handlers/participant_handlers.dart';
import 'package:soar_score_api_handlers/handlers/participants_handlers.dart';
import 'package:soar_score_api_handlers/middleware/failure_rate_limiter.dart';
import 'package:soar_score_core/soar_score_core.dart' show InvitationService;
import 'package:soar_score_api_handlers/handlers/participations_handlers.dart';
import 'package:soar_score_api_handlers/handlers/roles_handlers.dart';
import 'package:soar_score_api_handlers/handlers/public_publication_handlers.dart';
import 'package:soar_score_api_handlers/handlers/publication_handlers.dart';
import 'package:soar_score_api_handlers/handlers/results_handlers.dart';
import 'package:soar_score_api_handlers/handlers/scores_handlers.dart';
import 'package:soar_score_api_handlers/handlers/sync_handlers.dart';
import 'package:soar_score_api_handlers/handlers/teams_handlers.dart';
import 'package:soar_score_core/services/recalculation/recalculation_service.dart';
import 'package:soar_score_core/import/glider_score_import_runner.dart';
import 'package:soar_score_api_handlers/handlers/import_handlers.dart';

({
  Handler healthHandler,
  Handler apiHandler,
  Handler publicHandler,
  Handler participantHandler,
})
createHandlers(
  String name,
  String displayName,
  String version,
  Repository repository, {
  bool publishingEnabled = false,
  RecalculationService? recalculation,
  SyncVersions? syncVersions,
  GliderScoreImportRunner? gliderScoreImport,
  DrawRunner? drawRunner,
  InvitationService? invitations,
  FailureRateLimiter? invitationRateLimiter,
  Set<String> corsAllowedOrigins = const {},
  String selfScoringBaseUrl = defaultSelfScoringBaseUrl,
}) {
  final router = Router()
    ..get(
      '/ping',
      (Request request) => jsonResponse(<String, Object>{'status': 'ok'}),
    );
  addAccountClaimRoutes(router, repository);
  addAccountPreferencesRoutes(router, repository);
  addContestRoutes(router, repository, publishingEnabled: publishingEnabled);
  addConfigurationRoutes(router, repository, recalculation: recalculation);
  addLandingTableRoutes(router, repository);
  addParticipantRoutes(router, repository);
  addInvitationRoutes(
    router,
    repository,
    service: invitations,
    selfScoringBaseUrl: selfScoringBaseUrl,
  );
  addModelRoutes(router, repository);
  addRoleRoutes(router, repository);
  addParticipationRoutes(router, repository, recalculation: recalculation);
  addTeamRoutes(router, repository, recalculation: recalculation);
  addMatrixRoutes(
    router,
    repository,
    drawRunner: drawRunner ?? const IsolateDrawRunner(),
    recalculation: recalculation,
  );
  addScoreRoutes(
    router,
    repository,
    publishingEnabled: publishingEnabled,
    recalculation: recalculation,
  );
  addResultsRoutes(router, repository);
  addPublicationRoutes(router, repository, enabled: publishingEnabled);
  addImportRoutes(router, gliderScoreImport);
  addSyncRoutes(
    router,
    repository,
    versions: syncVersions ?? const SyncVersions.exactly(1),
    recalculation: recalculation,
  );

  return (
    healthHandler: createHealthHandler(name, displayName, version, repository),
    apiHandler: router.call,
    publicHandler: buildPublicHandler(repository, enabled: publishingEnabled),
    participantHandler: buildParticipantHandler(
      repository,
      service: invitations,
      limiter: invitationRateLimiter,
      allowedOrigins: corsAllowedOrigins,
    ),
  );
}
