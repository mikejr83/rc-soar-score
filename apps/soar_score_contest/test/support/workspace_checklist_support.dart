import 'package:soar_score_contest/services/matrix/matrix_page_data.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'configuration_fixtures.dart';
import 'matrix_test_support.dart';

/// A landing table named [name].
LandingTableView landingTableView(Id id, String name) => LandingTableView(
  content: LandingTableWithResults(
    table: LandingTable(
      id: id,
      name: name,
      inputUnit: LandingInputUnit.meters,
      createdAt: DateTime.utc(2026, 9),
    ),
    results: [
      LandingResult(
        id: Id.parse('019c0000-0000-7000-8000-0000000003f1'),
        landingTableId: id,
        entryKey: 'within_1m',
        displayValue: 'Within 1 m',
        pointValue: 10,
        ordinalPosition: 1,
      ),
    ],
  ),
  inUse: true,
);

/// The matrix page's data for a contest on the F5J system profile, whose
/// options and landing table the checklist facts read.
MatrixPageData f5jWorkspaceData({
  LifecycleState state = LifecycleState.configuring,
  ScoringAccess scoringAccess = ScoringAccess.closed,
  AdminLock adminLock = AdminLock.unlocked,
  bool withConfiguration = true,
  Map<String, Object?> core = const {},
  Map<String, Object?> discipline = const {},
  bool numbered = false,
  CurrentMatrix? matrix,
  List<ContestParticipation>? participations,
}) => MatrixPageData(
  contest: matrixContest(state: state).copyWithState(
    scoringAccess: scoringAccess,
    adminLock: adminLock,
    updatedAt: DateTime.utc(2026, 9),
  ),
  configuration: withConfiguration
      ? configRevision(3, core: core, discipline: discipline)
      : null,
  participations: participations ?? matrixParticipations(numbered: numbered),
  profiles: matrixProfiles(),
  teams: const [],
  memberships: const [],
  matrix: matrix ?? CurrentMatrix(),
);
