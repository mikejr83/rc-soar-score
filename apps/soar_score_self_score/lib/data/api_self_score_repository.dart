import 'dart:convert';

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
import '../session/guest_session_store.dart';
import 'self_score_repository.dart';

/// Reads the self-scoring pages from the API. The guest session token travels
/// in the [ApiClient]'s token provider, so the server decides whose data it
/// is; the contest and pilot ids in a page address are not trusted.
class ApiSelfScoreRepository implements SelfScoreRepository {
  ApiSelfScoreRepository(this._client, this._sessions);

  final ApiClient _client;

  /// Where the contest and pilot names come from. They were given with the
  /// session, so pages that only need a name do not ask the server again.
  final GuestSessionStore _sessions;

  static const _unreachable =
      'Could not reach the server. Check your connection and try again.';

  /// Runs an API call and turns its failures into words the person can read.
  /// The server's own message text is never shown: it is for logs, and the
  /// codes below are the contract.
  Future<T> _read<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiNetworkError {
      throw const SelfScoreLoadException(_unreachable);
    } on ApiHttpError catch (error) {
      final code = _codeOf(error);
      if (code == ParticipantErrorCodes.sessionInvalid ||
          error.statusCode == 401) {
        throw const SessionEndedException();
      }
      throw SelfScoreLoadException(_messageFor(error.statusCode, code));
    } on ApiException {
      throw const SelfScoreLoadException(
        'Could not load this page. Try again in a moment.',
      );
    }
  }

  /// The error code in a response, whether the body is the bare participant
  /// object or the director routes' `{"error": {...}}` envelope. Null when
  /// the body is empty or not JSON.
  static String? _codeOf(ApiHttpError error) {
    final bare = error.participantError?.code;
    if (bare != null) return bare;
    try {
      final decoded = jsonDecode(error.body);
      if (decoded is Map<String, dynamic>) {
        final inner = decoded['error'];
        if (inner is Map<String, dynamic> && inner['code'] is String) {
          return inner['code'] as String;
        }
      }
    } on Object {
      // Empty or not JSON.
    }
    return null;
  }

  static String _messageFor(int status, String? code) {
    return switch (code) {
      ParticipantErrorCodes.scoringClosed =>
        'Scoring is closed for this contest.',
      ParticipantErrorCodes.staleMatrix =>
        'The draw changed. Reload the page to see the new draw.',
      _ when status == 404 => 'This page could not be found.',
      _ when status == 403 => 'You cannot open this page.',
      _ when status == 429 => 'Too many requests. Wait a moment and try again.',
      _ => 'Could not load this page. Check your connection and try again.',
    };
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
        pilotNumber: answer.participant.pilotNumber,
        token: answer.sessionToken,
        role: answer.participant.role,
        expiresAt: answer.sessionExpiresAt,
      );
    } on ApiHttpError catch (error) {
      // Every way the server says no to a link reads the same, whatever
      // the body: the bare error, the envelope, or nothing at all.
      if (_codeOf(error) == ParticipantErrorCodes.invalidInvitation ||
          const {400, 404, 410}.contains(error.statusCode)) {
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
        details: _details(answer.score),
      );
    } on ApiHttpError catch (error) {
      final refusal = error.participantError;
      // A 401 ends the session whatever the body says.
      if (error.statusCode == 401 &&
          refusal?.code != ParticipantErrorCodes.sessionInvalid) {
        return const ScoreRejected(
          code: ParticipantErrorCodes.sessionInvalid,
          message: '',
        );
      }
      final transient =
          error.statusCode >= 500 ||
          error.statusCode == 408 ||
          error.statusCode == 429;
      // The director routes' envelope (`{"error": {"code": ...}}`) carries
      // the contest-state refusals, such as `scoring_closed` once the contest
      // is completed. That is a refusal, not a lost connection: queuing it
      // would retry a score that can never be accepted.
      final envelopeCode = refusal == null && !transient
          ? _codeOf(error)
          : null;
      if (envelopeCode != null) {
        return ScoreRejected(code: envelopeCode, message: '');
      }
      if (refusal == null || transient) {
        throw const SelfScoreOfflineException(_unreachable);
      }
      if (refusal.code == ParticipantErrorCodes.scoreAlreadySubmitted) {
        final score = refusal.acceptedScore?.flightScore;
        return ScoreAlreadySubmitted(
          flightScore: score == null ? null : ScoreFormat.score(score),
          details: refusal.acceptedScore == null
              ? null
              : _details(refusal.acceptedScore!),
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

  static ScoreDetails _details(ParticipantScoreDto score) {
    String? number(num? value) =>
        value == null ? null : ScoreFormat.score(value);
    return ScoreDetails(
      official: score.state == ParticipantScoreState.official,
      rawScore: number(score.rawScore),
      roundScore: number(score.roundScore),
      cumulativePenalty: number(score.cumulativePenalty),
      enteredBy: score.enteredBy,
    );
  }

  @override
  // `async`, so the error reaches the page as a failed future. A plain `=>
  // throw` threw while the page built, which crashed the contests page that
  // sits under every pilot page in the router's stack.
  Future<ContestsView> contests() async => throw const SelfScoreLoadException(
    'Signing in is coming soon. Use the link from your contest director.',
  );

  @override
  Future<TeamOverview> teamOverview(String contestId) async =>
      throw const SelfScoreLoadException(
        'The team overview is coming soon. Use the link from your contest '
        'director.',
      );

  @override
  Future<PilotOverview> pilotOverview(String contestId, String pilotId) =>
      _read(() async => _overview(await _client.participantOverview()));

  PilotOverview _overview(ParticipantOverviewDto dto) {
    final you = dto.participant.pilotName;
    final open = dto.access.code == 'open';
    return PilotOverview(
      contestName: dto.contest.name,
      teamName: dto.participant.teamName,
      pilotName: you,
      pilotNumber: dto.participant.pilotNumber,
      access: switch (dto.access.code) {
        'open' => ScoringAccess.open,
        'not_open' || 'not_started' => ScoringAccess.notStarted,
        'contest_completed' => ScoringAccess.completed,
        // Any other refusal is closed to the pilot.
        _ => ScoringAccess.closed,
      },
      rounds: [
        for (final round in dto.rounds)
          PilotRound(
            number: round.round,
            group: round.group,
            lane: round.lane,
            status: _status(round, scoringOpen: open),
            unavailableReason: open ? null : _accessReason(dto.access.code),
            enteredBy: switch (round.enteredBy) {
              null => null,
              final name when name == you => 'you',
              final name => name,
            },
          ),
      ],
    );
  }

  /// The server's state for the round decides the status. Closed access only
  /// affects rounds that have no score yet: a score that is already in stays
  /// as it is, and the pilot can still view it.
  PilotRoundStatus _status(
    ParticipantRoundDto round, {
    required bool scoringOpen,
  }) {
    return switch (round.state) {
      ParticipantScoreState.submitted ||
      ParticipantScoreState.official ||
      ParticipantScoreState.zero => PilotRoundStatus.submitted,
      ParticipantScoreState.retired => PilotRoundStatus.retired,
      ParticipantScoreState.reviewRequested ||
      ParticipantScoreState.underReview => PilotRoundStatus.pendingReview,
      ParticipantScoreState.locked => PilotRoundStatus.locked,
      ParticipantScoreState.notEntered || ParticipantScoreState.draft =>
        !scoringOpen
            ? PilotRoundStatus.locked
            : round.isNextToScore
            ? PilotRoundStatus.nextToScore
            : PilotRoundStatus.upcoming,
    };
  }

  /// A fixed sentence for why scoring is closed, whatever the server's text.
  static String _accessReason(String code) => switch (code) {
    'not_open' || 'not_started' => 'Scoring has not opened yet.',
    _ => 'Scoring is closed for this contest.',
  };

  @override
  Future<EntryContext> entryContext(
    String contestId,
    String pilotId,
    int round,
  ) => _read(() async {
    final session = _session();
    final entry = await _client.participantEntryContext(round);
    return EntryContext(
      pilotName: session.pilotName,
      pilotNumber: session.pilotNumber,
      round: entry.round,
      roundCount: entry.roundCount,
      group: entry.group,
      lane: entry.lane,
      taskType: entry.taskType,
      fieldKeys: [for (final field in entry.fields) field.key],
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
      submittedScore: switch (entry.submittedScore) {
        null => null,
        final score => SubmittedScore(
          components: score.components,
          flightScore: score.flightScore == null
              ? null
              : ScoreFormat.score(score.flightScore!),
          details: _details(score),
        ),
      },
    );
  });

  /// The stored session, which every page after the invitation needs. With
  /// none, the person has to open their link again.
  GuestSession _session() {
    final session = _sessions.read();
    if (session == null) throw const SessionEndedException();
    return session;
  }

  @override
  Future<GroupResults> groupResults(
    String contestId,
    String pilotId,
    int round,
  ) => _read(() async {
    final session = _session();
    final group = await _client.participantGroupResults(round);
    return GroupResults(
      contestName: session.contestName,
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
    final score = row.flightScore;
    // A missing score the server estimates still shows its value, flagged as
    // an estimate rather than an entered one.
    final estimated = kind == GroupRowKind.noScore && score != null;
    return GroupResultRow(
      name: row.pilotName,
      pilotNumber: row.pilotNumber,
      kind: kind,
      time: seconds == null ? null : FlightTimeInput.format(seconds.toDouble()),
      height: height?.round(),
      landing: row.landing,
      rawScore: row.rawScore == null ? null : ScoreFormat.score(row.rawScore!),
      score: score == null ? null : ScoreFormat.score(score),
      zeroReason: row.zeroReason?.toLowerCase(),
      isEstimate: estimated,
      isYou: row.isYou,
    );
  }

  @override
  Future<ResultsView> results(String contestId, {int? asOfRound}) =>
      _read(() async {
        final session = _session();
        final overall = await _client.participantOverallResults(
          asOfRound: asOfRound,
        );
        final place = overall.yourPlace;
        final score = overall.yourScore;
        return ResultsView(
          contestName: session.contestName,
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
