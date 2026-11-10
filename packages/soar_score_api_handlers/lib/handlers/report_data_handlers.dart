import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api_handlers/handlers/contest_authorization.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// The report data route (inside `/api/v1`):
///
/// - `GET /contests/{id}/report-data` answers what the reports read, in one
///   response. By default that is the contest, its configuration, its
///   participations, only its own participant profiles, teams, team
///   memberships, matrix and official scores. `?include=` names the parts as
///   a comma list: `facts` (the default), `scores` (the official scores
///   alone) and `standings`; `standings` reads the stored standings as of
///   `asOfRound=N` and the flight results of the rounds in
///   `rounds=1,2,3`. A round that does not exist is a 400, as on
///   `/results/rounds/{n}`. Authorized like the other contest reads.
///
/// The handler only translates between HTTP and [ReportDataService].
void addReportDataRoutes(Router router, Repository repository) {
  final service = ReportDataService(repository);

  router.get('/contests/<id>/report-data', (Request request, String id) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final include = _include(request.url.queryParameters);
    final data = await service.read(contestId, include: include);
    return jsonResponse(data.toJson());
  });
}

ReportInclude _include(Map<String, String> query) {
  final parts = (query['include'] ?? 'facts')
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toSet();
  const known = {'facts', 'scores', 'standings'};
  for (final part in parts) {
    if (!known.contains(part)) {
      throw ArgumentError.value(part, 'include', 'not a part of the report');
    }
  }
  final asOf = query['asOfRound'];
  final rounds = query['rounds'];
  int number(String text, String name) =>
      int.tryParse(text) ??
      (throw ArgumentError.value(text, name, 'not a round number'));
  if (parts.contains('standings') && asOf == null && rounds == null) {
    throw ArgumentError.value(
      'standings',
      'include',
      'needs asOfRound and/or rounds',
    );
  }
  return ReportInclude(
    facts: parts.contains('facts'),
    scores: parts.contains('scores'),
    asOfRound: parts.contains('standings') && asOf != null
        ? number(asOf, 'asOfRound')
        : null,
    rounds: parts.contains('standings') && rounds != null && rounds.isNotEmpty
        ? [for (final r in rounds.split(',')) number(r.trim(), 'rounds')]
        : const [],
  );
}
