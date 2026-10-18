import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/matrix_page_data.dart';
import '../workspace/workspace_facts.dart';
import 'reports_facts.dart';

/// Loads what [ReportsFacts] reduces. Any failed read is thrown: a report
/// built from part of the data would mislead, so the page offers a retry.
abstract final class ReportsFactsLoader {
  static Future<ReportsFacts> load(ApiClient client, Id id) async {
    final results = await Future.wait<Object?>([
      MatrixPageData.load(client, id),
      _scores(client, id),
    ]);
    final data = results[0]! as MatrixPageData;
    final scores = results[1]! as ContestScores;
    return ReportsFacts.derive(
      data: data,
      scores: scores,
      workspace: WorkspaceFacts.derive(data: data, scores: scores),
    );
  }

  /// A contest without a matrix may have no scores resource; that is no
  /// scores, not a failure.
  static Future<ContestScores> _scores(ApiClient client, Id id) async {
    try {
      return await client.scores(id);
    } on ApiHttpError catch (error) {
      if (error.statusCode == 404) {
        return ContestScores();
      }
      rethrow;
    }
  }
}
