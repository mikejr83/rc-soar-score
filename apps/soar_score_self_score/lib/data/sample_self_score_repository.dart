import '../models/account_link.dart';
import '../models/contests_view.dart';
import '../models/entry_context.dart';
import '../models/group_results.dart';
import '../models/guest_session.dart';
import '../models/landing_result.dart';
import '../models/link_candidate.dart';
import '../models/own_directory.dart';
import '../models/pilot_overview.dart';
import '../models/pilot_round.dart';
import '../models/results_view.dart';
import '../models/score_submission.dart';
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
  Future<GuestSession> claimInvitation(String credential) =>
      acceptInvitation(credential);

  @override
  Future<SubmitResult> submitScore(ScoreSubmission submission) async {
    _requireContest(submission.contestId);
    return const ScoreAccepted(flightScore: '863');
  }

  @override
  Future<ContestsView> contests() async => ContestsView(
    contests: [
      ContestSummary(
        participationId: '12',
        contestId: SampleData.contestId,
        name: SampleData.contestName,
        startDate: DateTime.utc(2026, 10, 10),
        endDate: DateTime.utc(2026, 10, 11),
        phase: ContestPhase.inProgress,
        location: 'Denver, CO',
      ),
    ],
  );

  @override
  Future<GuestSession> openContest(String participationId) async {
    if (participationId != '12') throw const ContestNotOnListException();
    return acceptInvitation(sampleCredential);
  }

  @override
  Future<List<LinkCandidate>> linkCandidates() async => [
    LinkCandidate(
      id: 'sample-candidate',
      pilotName: SampleData.pilotName,
      contests: [
        LinkCandidateContest(
          name: SampleData.contestName,
          startDate: DateTime.utc(2026, 10, 10),
          endDate: DateTime.utc(2026, 10, 11),
        ),
      ],
    ),
  ];

  /// Already has an entry, so signing in goes straight on.
  @override
  Future<OwnDirectory> ownDirectory() async => const OwnDirectory(
    hasEntry: true,
    initial: DirectoryDetails(firstName: 'Penny', lastName: 'Pilot'),
    emailAvailable: true,
  );

  @override
  Future<void> saveOwnDirectory(DirectoryDetails details) async {}

  @override
  Future<void> deleteOwnDirectory() async {}

  @override
  Future<List<AccountLink>> accountLinks() async => const [
    AccountLink(id: 'sample-link', pilotName: SampleData.pilotName),
  ];

  @override
  Future<void> endAccountLink(String linkId) async {}

  @override
  Future<void> confirmLinkCandidate(String candidateId) async {}

  @override
  Future<void> declineLinkCandidate(String candidateId) async {}

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
  Future<String> invitationLink() async =>
      'https://score.rcsoarscore.com/invitations/sample';

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
      lastOpenRound: [
        for (final r in rounds)
          if (r.status != PilotRoundStatus.upcoming) r.number,
      ].fold<int>(round, (a, b) => b > a ? b : a),
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
