import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// The results routes (all inside `/api/v1`):
///
/// - `GET /contests/{id}/results` is the standings and team totals as of the
///   latest scored round, with `stale` and `preliminary` flags; `?asOfRound=N`
///   asks for the stored standings as of round `N` instead;
/// - `GET /contests/{id}/results/rounds/{n}` is every flight result of round
///   `n`, grouped by group;
/// - `POST /contests/{id}/results/recalculation` rebuilds the results now and
///   returns them.
///
/// The handlers only translate between HTTP and [ResultsService].
void addResultsRoutes(Router router, Repository repository) {
  final service = ResultsService(repository);

  router.get('/contests/<id>/results', (Request request, String id) async {
    requirePrincipal(request);
    final asOfRound = request.url.queryParameters['asOfRound'];
    final round = asOfRound == null ? null : int.tryParse(asOfRound);
    if (asOfRound != null && round == null) {
      throw ArgumentError.value(asOfRound, 'asOfRound', 'not a round number');
    }
    final results = await service.read(Id.parse(id), asOfRound: round);
    return jsonResponse(results.toJson());
  });

  router.get('/contests/<id>/results/rounds/<ordinal>', (
    Request request,
    String id,
    String ordinal,
  ) async {
    requirePrincipal(request);
    final round = int.tryParse(ordinal);
    if (round == null) {
      throw ArgumentError.value(ordinal, 'ordinal', 'not a round number');
    }
    final results = await service.round(Id.parse(id), round);
    return jsonResponse(results.toJson());
  });

  router.post('/contests/<id>/results/recalculation', (
    Request request,
    String id,
  ) async {
    requirePrincipal(request);
    final results = await service.recalculate(Id.parse(id));
    return jsonResponse(results.toJson());
  });
}
