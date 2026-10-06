import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_core/repositories/repository.dart';
import 'package:soar_score_core/services/services.dart';

Handler createContestsHandler(Repository repository) {
  final router = Router();

  final contestsService = ContestsService(repository);

  router.get('/contests', (Request request) async {
    final contests = await contestsService.getContests();

    return jsonResponse(<String, dynamic>{
      'contests': [for (final contest in contests) contest.toJson()],
    });
  });

  return router.call;
}
