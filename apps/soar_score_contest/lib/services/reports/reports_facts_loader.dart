import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/matrix_page_data.dart';
import '../workspace/workspace_facts.dart';
import 'reports_facts.dart';

/// Loads what [ReportsFacts] reduces, in one request (`report-data`). Any
/// failed read is thrown: a report built from part of the data would
/// mislead, so the page offers a retry.
abstract final class ReportsFactsLoader {
  static Future<ReportsFacts> load(ApiClient client, Id id) async {
    final report = await client.reportData(id);
    final data = MatrixPageData.fromReportData(report);
    final scores = report.scores!;
    return ReportsFacts.derive(
      data: data,
      scores: scores,
      workspace: WorkspaceFacts.derive(data: data, scores: scores),
    );
  }
}
