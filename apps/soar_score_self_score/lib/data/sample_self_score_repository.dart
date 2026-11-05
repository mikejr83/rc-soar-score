import '../models/contests_view.dart';
import '../models/entry_context.dart';
import '../models/group_results.dart';
import '../models/guest_session.dart';
import '../models/landing_result.dart';
import '../models/pilot_overview.dart';
import '../models/results_view.dart';
import '../models/team_overview.dart';
import '../models/team_pilot.dart';
import 'sample_data.dart';
import 'self_score_repository.dart';

/// Serves [SampleData] through the repository interface until the API exists.
/// Only the sample contest id is known; any other id fails the way a missing
/// contest will on the server.
class SampleSelfScoreRepository implements SelfScoreRepository {
  const SampleSelfScoreRepository({
    this.landingTable = SampleData.landingTable,
  });

  /// Lets a test serve a landing table of any size.
  final List<LandingResult> landingTable;

  void _requireContest(String contestId) {
    if (contestId != SampleData.contestId) {
      throw const SelfScoreLoadException('This contest could not be found.');
    }
  }

  /// The credential the sample contest's pilot link carries.
  static const sampleCredential = 'sample-link';

  @override
  Future<GuestSession> acceptInvitation(String credential) async {
    if (credential != sampleCredential) {
      throw const InvalidInvitationException();
    }
    return GuestSession(
      contestId: SampleData.contestId,
      contestName: SampleData.contestName,
      pilotId: '12',
      pilotName: SampleData.pilotName,
      token: 'sample-token',
      expiresAt: DateTime.utc(2099),
    );
  }

  @override
  Future<ContestsView> contests() async => const ContestsView(
    matchPrompt:
        'Your email matches ${SampleData.pilotName}, pilot 12, in '
        '${SampleData.contestName}.',
    contests: [
      ContestSummary(
        id: SampleData.contestId,
        name: SampleData.contestName,
        dates: 'Sat 10 Oct 2026 to Sun 11 Oct 2026',
        next: 'Round 4, Group B, lane 2',
      ),
    ],
  );

  @override
  Future<TeamOverview> teamOverview(String contestId) async {
    _requireContest(contestId);
    return const TeamOverview(
      contestName: SampleData.contestName,
      teamName: SampleData.teamName,
      pilots: [
        TeamPilot(
          id: '12',
          name: 'Jane Smith',
          number: 12,
          state: TeamPilotState.upNow,
          slot: 'Round 4 · Group B · Lane 1',
        ),
        TeamPilot(
          id: '7',
          name: 'Tom Reid',
          number: 7,
          state: TeamPilotState.upNext,
          slot: 'Round 4 · Group C · Lane 3',
        ),
        TeamPilot(
          id: '3',
          name: 'Ana Lopez',
          number: 3,
          state: TeamPilotState.justFlown,
          slot: 'Round 3 · Group A · Lane 2',
          needsScoreRound: '3',
        ),
        TeamPilot(
          id: '21',
          name: 'Sam Park',
          number: 21,
          state: TeamPilotState.retired,
        ),
        TeamPilot(
          id: '15',
          name: 'Li Wei',
          number: 15,
          state: TeamPilotState.scheduled,
          slot: 'Round 5 · Group D · Lane 4',
        ),
        TeamPilot(
          id: '9',
          name: 'Kate Brooks',
          number: 9,
          state: TeamPilotState.scheduled,
          slot: 'Round 5 · Group D · Lane 2',
        ),
      ],
      standings: SampleData.teamStandings,
    );
  }

  @override
  Future<PilotOverview> pilotOverview(String contestId, String pilotId) async {
    _requireContest(contestId);
    return PilotOverview(
      contestName: SampleData.contestName,
      teamName: SampleData.teamName,
      pilotName: SampleData.pilotNameOf(pilotId),
      pilotNumber: int.tryParse(pilotId) ?? 0,
      rounds: SampleData.pilotRounds,
    );
  }

  @override
  Future<EntryContext> entryContext(
    String contestId,
    String pilotId,
    int round,
  ) async {
    _requireContest(contestId);
    final rounds = SampleData.pilotRounds;
    if (round < 1 || round > rounds.length) {
      throw const SelfScoreLoadException('This round could not be found.');
    }
    final draw = rounds[round - 1];
    return EntryContext(
      pilotName: SampleData.pilotNameOf(pilotId),
      pilotNumber: int.tryParse(pilotId) ?? 0,
      round: round,
      roundCount: rounds.length,
      group: draw.group,
      lane: draw.lane,
      landingTable: landingTable,
    );
  }

  @override
  Future<GroupResults> groupResults(
    String contestId,
    String pilotId,
    int round,
  ) async {
    _requireContest(contestId);
    final rounds = SampleData.pilotRounds;
    if (round < 1 || round > rounds.length) {
      throw const SelfScoreLoadException('This round could not be found.');
    }
    return GroupResults(
      contestName: SampleData.contestName,
      round: round,
      group: rounds[round - 1].group,
      latestRound: SampleData.latestRound,
      rows: SampleData.groupBResults,
    );
  }

  @override
  Future<ResultsView> results(String contestId, {int? asOfRound}) async {
    _requireContest(contestId);
    final snapshot = SampleData.results[asOfRound ?? SampleData.latestRound];
    if (snapshot == null) {
      throw const SelfScoreLoadException(
        'Results for that round are not available.',
      );
    }
    return ResultsView(
      contestName: SampleData.contestName,
      latestRound: SampleData.latestRound,
      heldRound: SampleData.heldRound,
      snapshot: snapshot,
    );
  }
}
