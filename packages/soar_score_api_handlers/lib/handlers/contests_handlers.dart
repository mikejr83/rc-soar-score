import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_core/repositories/repository.dart';
import 'package:soar_score_core/services/services.dart';

Handler createContestsHandler(Repository repository) {
  final router = Router();

  final contestsService = ContestsService(repository);

  // Define your contest-related routes here.
  // Example:
  router.get('/contests', (Request request) async {
    // Handle fetching contests
    final contests = await contestsService.getContests();

    return jsonResponse(Map<String, dynamic>.from({'contests': contests}));
  });

  return router.call;
}
