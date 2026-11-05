import 'package:soar_score_api/soar_score_api.dart';

import '../models/contests_view.dart';
import '../models/entry_context.dart';
import '../models/group_result_row.dart';
import '../models/group_results.dart';
import '../models/guest_session.dart';
import '../models/landing_result.dart';
import '../models/pilot_overview.dart';
import '../models/pilot_round.dart';
import '../models/results_snapshot.dart';
import '../models/results_view.dart';
import '../models/score_submission.dart';
import '../models/team_overview.dart';
import '../services/flight_time_input.dart';
import '../services/score_format.dart';
import 'self_score_repository.dart';

/// Reads the self-scoring pages from the API. The guest session token travels
/// in the [ApiClient]'s token provider, so the server decides whose data it
/// is; the contest and pilot ids in a page address are not trusted.
class ApiSelfScoreRepository implements SelfScoreRepository {
  ApiSelfScoreRepository(this._client);

  final ApiClient _client;

  static const _unreachable =
      'Could not reach the server. Check your connection and try again.';

  /// Runs an API call and turns its failures into words the person can read.
  Future<T> _read<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiNetworkError {
      throw const SelfScoreLoadException(_unreachable);
    } on ApiHttpError catch (error) {
      final refusal = error.participantError;
      if (refusal?.code == ParticipantErrorCodes.sessionInvalid ||
          error.statusCode == 401) {
        throw const SessionEndedException();
      }
      if (error.statusCode == 404) {
        throw const SelfScoreLoadException('This page could not be found.');
      }
      throw SelfScoreLoadException(
        refusal?.message ??
            'Could not load this page. Check your connection and try again.',
      );
    } on ApiException {
      throw const SelfScoreLoadException(
        'Could not load this page. Try again in a moment.',
      );
    }
  }

  @override
  Future<GuestSession> acceptInvitation(String credential) async {
    try {
      final answer = await _client.resolveInvitation(
        ResolveInvitationRequest(credential: credential),
      );
      return GuestSession(
        contestId: answer.contest.contestId.value,
        contestName: answer.contest.name,
        pilotId: answer.participant.participationId.value,
        pilotName: answer.participant.pilotName,
        token: answer.sessionToken,
        role: answer.participant.role,
        expiresAt: answer.sessionExpiresAt,
      );
    } on ApiHttpError catch (error) {
      if (error.participantError?.code ==
          ParticipantErrorCodes.invalidInvitation) {
        throw const InvalidInvitationException();
      }
      // Rate limiting and server faults are not the link's fault.
      throw const SelfScoreLoadException(_unreachable);
    } on ApiException {
      throw const SelfScoreLoadException(_unreachable);
    }
  }

  @override
  Future<SubmitResult> submitScore(ScoreSubmission submission) async {
    try {
      final answer = await _client.submitParticipantScore(
        submission.round,
        SubmitParticipantScoreRequest(
          clientMutationId: submission.clientMutationId,
          matrixRevision: submission.matrixRevision,
          components: submission.components,
        ),
      );
      final score = answer.score.flightScore;
      return ScoreAccepted(
        flightScore: score == null ? null : ScoreFormat.score(score),
        nextRound: answer.nextRound,
      );
    } on ApiHttpError catch (error) {
      final refusal = error.participantError;
      final transient =
          error.statusCode >= 500 ||
          error.statusCode == 408 ||
          error.statusCode == 429;
      if (refusal == null || transient) {
        throw const SelfScoreOfflineException(_unreachable);
      }
      if (refusal.code == ParticipantErrorCodes.scoreAlreadySubmitted) {
        final score = refusal.acceptedScore?.flightScore;
        return ScoreAlreadySubmitted(
          flightScore: score == null ? null : ScoreFormat.score(score),
        );
      }
      return ScoreRejected(
        code: refusal.code,
        message: refusal.message,
        fields: [for (final field in refusal.fieldErrors) field.field],
      );
    } on ApiException {
      // Network failure or an answer that could not be read: the score may or
      // may not be stored, and sending it again with the same id is safe.
      throw const SelfScoreOfflineException(_unreachable);
    }
  }

  @override
  Future<ContestsView> contests() => throw const SelfScoreLoadException(
    'Signing in is coming soon. Use the link from your contest director.',
  );

  @override
  Future<TeamOverview> teamOverview(String contestId) =>
      throw const SelfScoreLoadException(
        'The team overview is coming soon. Use the link from your contest '
        'director.',
      );

  @override
  Future<PilotOverview> pilotOverview(String contestId, String pilotId) =>
      _read(() async => _overview(await _client.participantOverview()));

  PilotOverview _overview(ParticipantOverviewDto dto) {
    final you = dto.participant.pilotName;
    return PilotOverview(
      contestName: dto.contest.name,
      teamName: dto.participant.teamName,
      pilotName: you,
      pilotNumber: dto.participant.pilotNumber,
      rounds: [
        for (final round in dto.rounds)
          PilotRound(
            number: round.round,
            group: round.group,
            lane: round.lane,
            status: _status(round, locked: dto.access.code != 'open'),
            enteredBy: switch (round.enteredBy) {
              null => null,
              final name when name == you => 'you',
              final name => name,
            },
          ),
      ],
    );
  }

  PilotRoundStatus _status(ParticipantRoundDto round, {required bool locked}) {
    return switch (round.state) {
      ParticipantScoreState.submitted ||
      ParticipantScoreState.official ||
      ParticipantScoreState.zero ||
      ParticipantScoreState.retired => PilotRoundStatus.submitted,
      ParticipantScoreState.reviewRequested ||
      ParticipantScoreState.underReview => PilotRoundStatus.pendingReview,
      ParticipantScoreState.locked => PilotRoundStatus.locked,
      ParticipantScoreState.notEntered || ParticipantScoreState.draft =>
        round.isNextToScore && !locked
            ? PilotRoundStatus.nextToScore
            : PilotRoundStatus.locked,
    };
  }

  @override
  Future<EntryContext> entryContext(
    String contestId,
    String pilotId,
    int round,
  ) => _read(() async {
    final (overview, entry) = await (
      _client.participantOverview(),
      _client.participantEntryContext(round),
    ).wait;
    return EntryContext(
      pilotName: overview.participant.pilotName,
      pilotNumber: overview.participant.pilotNumber,
      round: entry.round,
      roundCount: entry.roundCount,
      group: entry.group,
      lane: entry.lane,
      landingTable: [
        for (final option in entry.landingTable)
          LandingResult(
            id: option.id,
            label: option.label,
            points: option.points,
            description: option.description,
          ),
      ],
      allowsMotorRestart: entry.allowsMotorRestart,
      matrixRevision: entry.matrixRevision,
      alreadySubmitted: switch (entry.state) {
        ParticipantScoreState.notEntered ||
        ParticipantScoreState.draft => false,
        _ => true,
      },
    );
  });

  @override
  Future<GroupResults> groupResults(
    String contestId,
    String pilotId,
    int round,
  ) => _read(() async {
    final (overview, group) = await (
      _client.participantOverview(),
      _client.participantGroupResults(round),
    ).wait;
    return GroupResults(
      contestName: overview.contest.name,
      round: group.round,
      group: group.group,
      latestRound: group.latestRound,
      rows: [for (final row in group.rows) _groupRow(row)],
    );
  });

  GroupResultRow _groupRow(ParticipantGroupRowDto row) {
    final kind = switch (row.state) {
      _ when row.reviewPending => GroupRowKind.pendingReview,
      ParticipantScoreState.zero => GroupRowKind.zero,
      ParticipantScoreState.notEntered ||
      ParticipantScoreState.draft => GroupRowKind.noScore,
      _ => GroupRowKind.scored,
    };
    final seconds = row.timeFlownSeconds;
    final height = row.launchHeight;
    final detail = [
      if (kind == GroupRowKind.noScore && row.flightScore != null)
        'Estimate ${ScoreFormat.score(row.flightScore!)}',
      if (height != null) 'Height ${ScoreFormat.score(height)} m',
      ?row.landing,
    ].join(' · ');
    return GroupResultRow(
      name: row.pilotName,
      pilotNumber: row.pilotNumber,
      kind: kind,
      time: seconds == null ? null : FlightTimeInput.format(seconds.toDouble()),
      score: kind == GroupRowKind.noScore || row.flightScore == null
          ? null
          : ScoreFormat.score(row.flightScore!),
      detail: detail.isEmpty ? null : detail,
      zeroReason: row.zeroReason?.toLowerCase(),
      isYou: row.isYou,
    );
  }

  @override
  Future<ResultsView> results(String contestId, {int? asOfRound}) =>
      _read(() async {
        final (overview, overall) = await (
          _client.participantOverview(),
          _client.participantOverallResults(asOfRound: asOfRound),
        ).wait;
        final place = overall.yourPlace;
        final score = overall.yourScore;
        return ResultsView(
          contestName: overview.contest.name,
          latestRound: overall.latestRound,
          heldRound: overall.heldAtRound,
          snapshot: ResultsSnapshot(
            round: overall.asOfRound,
            ordinal: place == null ? '–' : ScoreFormat.ordinal(place),
            score: score == null ? '–' : ScoreFormat.score(score),
            pilots: [
              for (final line in overall.standings)
                StandingLine(
                  place: line.tied ? '${line.place}=' : '${line.place}',
                  name: line.pilotName,
                  score: ScoreFormat.score(line.score),
                  isYou: line.isYou,
                  tied: line.tied,
                ),
            ],
            // Absent in the first field release, which has no teams.
            teams: [
              for (final team in overall.teamStandings ?? const [])
                StandingLine(
                  place: team.tied ? '${team.place}=' : '${team.place}',
                  name: team.teamName,
                  score: ScoreFormat.score(team.score),
                  isYou: team.isYourTeam,
                  tied: team.tied,
                ),
            ],
          ),
        );
      });
}
