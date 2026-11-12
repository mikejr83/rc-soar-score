import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api_handlers/handlers/contest_authorization.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/middleware/request_limits.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ResultsHandlers');

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
  // A recalculation rebuilds every result of the contest.
  final recalculationLimiter = RequestRateLimiter(maxRequests: 10);

  router.get('/contests/<id>/results', (Request request, String id) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);

    final asOfRound = request.url.queryParameters['asOfRound'];
    final round = asOfRound == null ? null : int.tryParse(asOfRound);

    if (asOfRound != null) {
      _logger.fine('Fetching results for contest $id as of round $round');
    } else {
      _logger.fine('Fetching results for contest $id');
    }

    if (asOfRound != null && round == null) {
      throw ArgumentError.value(asOfRound, 'asOfRound', 'not a round number');
    }
    final results = await service.read(contestId, asOfRound: round);
    return jsonResponse(results.toJson());
  });

  router.get('/contests/<id>/results/rounds/<ordinal>', (
    Request request,
    String id,
    String ordinal,
  ) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final round = int.tryParse(ordinal);
    if (round == null) {
      throw ArgumentError.value(ordinal, 'ordinal', 'not a round number');
    }
    final results = await service.round(contestId, round);
    return jsonResponse(results.toJson());
  });

  router.post('/contests/<id>/results/recalculation', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    recalculationLimiter.check(principal.accountId.toString());
    _logger.fine('Recalculating results for contest $id');
    final results = await service.recalculate(contestId);
    return jsonResponse(results.toJson());
  });
}
