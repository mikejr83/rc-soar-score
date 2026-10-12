import 'package:soar_score_contest/services/matrix/matrix_page_data.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_resolver.dart';
import 'package:soar_score_contest/services/workspace/publication_facts.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'matrix_test_support.dart';
import 'workspace_facts_support.dart';

/// Facts for the fixture contest in the given condition.
WorkspaceFacts stepFacts({
  LifecycleState state = LifecycleState.configuring,
  AdminLock lock = AdminLock.unlocked,
  ScoringAccess access = ScoringAccess.closed,
  CurrentMatrix? matrix,
  Map<(int, int), DateTime>? scored,
  bool withConfiguration = true,
  List<ContestParticipation>? participations,
  Map<String, Object?> core = const {},
  PublicationFacts publication = PublicationFacts.unknown,
  bool offline = false,
  ContestScores? scores,
}) {
  final base = matrixContest(state: state, lock: lock);
  final contest = Contest(
    id: base.id,
    name: base.name,
    startDateTime: base.startDateTime,
    endDateTime: base.endDateTime,
    timezone: base.timezone,
    lifecycleState: state,
    scoringAccess: access,
    adminLock: lock,
    createdAt: base.createdAt,
    updatedAt: base.updatedAt,
  );
  final data = MatrixPageData(
    contest: contest,
    configuration: withConfiguration ? matrixConfiguration(core) : null,
    participations: participations ?? matrixParticipations(),
    profiles: matrixProfiles(),
    teams: const [],
    memberships: const [],
    matrix: matrix ?? CurrentMatrix(),
  );
  return WorkspaceFacts.derive(
    data: data,
    scores:
        scores ??
        (scored == null || matrix == null ? null : scoresFor(matrix, scored)),
    publication: publication,
    isOffline: offline,
  );
}

/// The step for [facts] at [minutes] after the fixture start.
NextStep stepAt(
  WorkspaceFacts facts, {
  int minutes = 0,
  bool dismissed = false,
}) => resolveNextStep(
  facts,
  now: at(minutes),
  completionSuggestionDismissed: dismissed,
);

/// Every pilot scored in both rounds, one score per five minutes.
Map<(int, int), DateTime> allScored() => {
  for (var r = 1; r <= 2; r++)
    for (var p = 1; p <= 4; p++) (r, p): at(r * 20 + p * 5),
};

/// Round 1 fully scored; round 2 has pilot 1 and 3 (group 1) scored.
Map<(int, int), DateTime> midRoundTwo() => {
  for (var p = 1; p <= 4; p++) (1, p): at(p * 5),
  (2, 1): at(60),
  (2, 3): at(65),
};
