import 'package:soar_score_contest/services/matrix/matrix_page_data.dart';
import 'package:soar_score_contest/services/reports/draw_matrix/draw_matrix_data.dart';
import 'package:soar_score_contest/services/reports/reports_facts.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'matrix_test_support.dart';
import 'workspace_facts_support.dart';

/// The fixture contest's matrix page data: four pilots, two rounds, two groups.
MatrixPageData drawnPage({bool lanes = false}) =>
    workspaceData(matrix: drawnMatrix(lanes: lanes));

/// The reports facts for [page], with no scores.
ReportsFacts factsOfPage(MatrixPageData page) {
  final scores = ContestScores();
  return ReportsFacts.derive(
    data: page,
    scores: scores,
    workspace: WorkspaceFacts.derive(data: page, scores: scores),
  );
}

/// A synthetic draw: [rounds] rounds of [groupSizes], pilots numbered in
/// order, named "Pilot 1", with lanes by position.
DrawMatrixData syntheticDraw({
  int rounds = 6,
  List<int> groupSizes = const [8, 8, 7, 7],
  bool lanes = true,
  String Function(int pilot)? name,
  String? className,
}) {
  var next = 0;
  return DrawMatrixData(
    hasLanes: lanes,
    rounds: [
      for (var r = 1; r <= rounds; r++)
        DrawMatrixRound(
          ordinal: r,
          groups: [
            for (var g = 0; g < groupSizes.length; g++)
              DrawMatrixGroup(
                label: DrawMatrixData.groupLabel(g),
                pilots: [
                  for (var k = 0; k < groupSizes[g]; k++)
                    DrawMatrixPilot(
                      name: (name ?? (n) => 'Pilot $n')(next++),
                      lane: lanes ? k + 1 : null,
                      number: 100 + k,
                      className: className,
                    ),
                ],
              ),
          ],
        ),
    ],
  );
}
