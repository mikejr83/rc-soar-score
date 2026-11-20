import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/matrix_page_data.dart';
import '../workspace/workspace_facts.dart';
import 'reports_facts.dart';

/// Loads the report data and, for a completed contest with scores, the
/// latest stored standings. A failed read reaches the page's retry state.
abstract final class ReportsFactsLoader {
  static Future<ReportsFacts> load(ApiClient client, Id id) async {
    final report = await client.reportData(id);
    final data = MatrixPageData.fromReportData(report);
    final scores = report.scores!;
    final workspace = WorkspaceFacts.derive(data: data, scores: scores);
    final latest =
        data.contest.lifecycleState == LifecycleState.completed &&
            workspace.rounds.any((round) => round.scored > 0)
        ? await client.results(id)
        : null;
    return ReportsFacts.derive(
      data: data,
      scores: scores,
      workspace: workspace,
      latestStandings: latest,
    );
  }
}
