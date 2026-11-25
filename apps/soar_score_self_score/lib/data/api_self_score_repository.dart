import 'dart:convert';

import 'package:soar_score_api/soar_score_api.dart';

import '../auth/auth_session.dart';
import '../models/contests_view.dart';
import '../models/entry_context.dart';
import '../models/group_result_row.dart';
import '../models/group_results.dart';
import '../models/guest_session.dart';
import '../models/officialization_policy.dart';
import '../models/landing_result.dart';
import '../models/link_candidate.dart';
import '../models/own_directory.dart';
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

  static const _notFound = 'This page could not be found.';

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
    } on AuthTokenUnavailableException {
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
      _ when status == 404 => _notFound,
      _ when status == 403 => 'You cannot open this page.',
      _ when status == 429 => 'Too many requests. Wait a moment and try again.',
      _ => 'Could not load this page. Check your connection and try again.',
    };
  }

  @override
  Future<GuestSession> acceptInvitation(String credential) => _openInvitation(
    () => _client.resolveInvitation(
      ResolveInvitationRequest(credential: credential),
    ),
  );

  @override
  Future<GuestSession> claimInvitation(String credential) => _openInvitation(
    () => _client.claimInvitation(
      ResolveInvitationRequest(credential: credential),
    ),
    claim: true,
  );

  Future<GuestSession> _openInvitation(
    Future<ResolveInvitationResponse> Function() open, {
    bool claim = false,
  }) async {
    try {
      return _sessionOf(await open());
    } on ApiHttpError catch (error) {
      // Another account already holds this pilot: the pilot can still
      // continue as a guest.
      if (claim && error.statusCode == 409) {
        throw const PilotAlreadyLinkedException();
      }
      if (claim && error.statusCode == 401) {
        throw const AccountSignInExpiredException();
      }
      // 404 `link_not_found` is the account, not the link: an invalid link
      // answers `invalid_invitation`.
      if (claim && _codeOf(error) == 'link_not_found') {
        throw const AccountCannotLinkException();
      }
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

  static GuestSession _sessionOf(ResolveInvitationResponse answer) =>
      GuestSession(
        contestId: answer.contest.contestId.value,
        contestName: answer.contest.name,
        pilotId: answer.participant.participationId.value,
        pilotName: answer.participant.pilotName,
        pilotNumber: answer.participant.pilotNumber,
        token: answer.sessionToken,
        role: answer.participant.role,
        expiresAt: answer.sessionExpiresAt,
      );

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
  Future<ContestsView> contests() async {
    try {
      final answer = await _read(_client.accountParticipations);
      return ContestsView(
        contests: [for (final row in answer.participations) _summary(row)],
      );
    } on SessionEndedException {
      // The account routes answer 401 when the access token is no longer
      // good. That is the sign-in, not the guest session.
      throw const SignedOutException();
    }
  }

  static ContestSummary _summary(AccountParticipationDto row) => ContestSummary(
    participationId: row.participationId.value,
    contestId: row.contestId.value,
    name: row.contestName,
    startDate: _day(row.startDate),
    endDate: _day(row.endDate),
    phase: switch (row.phase) {
      AccountParticipationPhase.inProgress => ContestPhase.inProgress,
      AccountParticipationPhase.completed => ContestPhase.completed,
      _ => ContestPhase.invited,
    },
    location: _place(row),
    publicResultsUrl: _publicUrl(row.publicResultsUrl),
  );

  /// `YYYY-MM-DD` as UTC midnight.
  static DateTime _day(String text) {
    final parts = text.split('-').map(int.parse).toList();
    return DateTime.utc(parts[0], parts[1], parts[2]);
  }

  static String? _place(AccountParticipationDto row) {
    final parts = [
      for (final part in [row.city, row.state, row.country])
        if (part != null && part.trim().isNotEmpty) part.trim(),
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Only a web address the page can open; anything else is no address.
  static Uri? _publicUrl(String? text) {
    final uri = text == null ? null : Uri.tryParse(text);
    return uri != null && (uri.isScheme('https') || uri.isScheme('http'))
        ? uri
        : null;
  }

  @override
  Future<GuestSession> openContest(String participationId) async {
    try {
      return _sessionOf(
        await _read(() => _client.openAccountParticipation(participationId)),
      );
    } on SessionEndedException {
      throw const SignedOutException();
    } on SelfScoreLoadException catch (error) {
      // `_read` words a 404 as a missing page; here it means the contest left
      // the list (`link_not_found`).
      if (error.message == _notFound) throw const ContestNotOnListException();
      rethrow;
    }
  }

  @override
  Future<List<LinkCandidate>> linkCandidates() async {
    final answer = await _readAccount(_client.linkCandidates);
    return [
      for (final candidate in answer.candidates)
        LinkCandidate(
          id: candidate.id.value,
          pilotName: '${candidate.firstName} ${candidate.lastName}'.trim(),
          contests: [
            for (final contest in candidate.contests)
              LinkCandidateContest(
                name: contest.name,
                startDate: _day(contest.startDate),
                endDate: _day(contest.endDate),
              ),
          ],
        ),
    ];
  }

  @override
  Future<OwnDirectory> ownDirectory() async {
    final state = await _readAccount(_client.getDirectoryEntry);
    final entry = state.entry;
    return OwnDirectory(
      hasEntry: entry != null,
      emailAvailable: state.emailAvailable,
      initial: entry == null
          ? DirectoryDetails(
              firstName: state.suggestedFirstName,
              lastName: state.suggestedLastName,
            )
          : DirectoryDetails(
              firstName: entry.firstName,
              lastName: entry.lastName,
              club: entry.club,
              faiNumber: entry.faiNumber,
              nationalOrgId: entry.nationalOrgId,
              country: entry.country,
              city: entry.city,
              state: entry.state,
              isListed: entry.isListed,
              emailVisibleToDirectors: entry.emailVisibleToDirectors,
            ),
    );
  }

  @override
  Future<void> saveOwnDirectory(DirectoryDetails details) => _readAccount(
    () => _client.putDirectoryEntry(
      PutDirectoryEntryRequest(
        firstName: details.firstName,
        lastName: details.lastName,
        club: details.club,
        faiNumber: details.faiNumber,
        nationalOrgId: details.nationalOrgId,
        country: details.country,
        city: details.city,
        state: details.state,
        isListed: details.isListed,
        emailVisibleToDirectors: details.emailVisibleToDirectors,
      ),
    ),
  );

  @override
  Future<void> confirmLinkCandidate(String candidateId) => _answerCandidate(
    () => _client.confirmLinkCandidate(ApiId.parse(candidateId)),
  );

  @override
  Future<void> declineLinkCandidate(String candidateId) => _answerCandidate(
    () => _client.declineLinkCandidate(ApiId.parse(candidateId)),
  );

  /// Sends an "Is this you?" answer. Only the two documented refusals end the
  /// card: `already_linked` (another account holds the pilot) and
  /// `link_not_found` (not a match any more). Any other answer, whatever its
  /// status (a 409 `invitations_not_available` or `backend_only` included),
  /// may pass, so the card stays and the answer can be sent again.
  Future<void> _answerCandidate(Future<Object?> Function() send) async {
    try {
      await _readAccount(send);
    } on ApiHttpError catch (error) {
      throw switch ((error.statusCode, _codeOf(error))) {
        (409, 'already_linked') => const LinkCandidateGoneException(
          LinkCandidateGoneReason.alreadyLinked,
        ),
        (404, 'link_not_found') => const LinkCandidateGoneException(
          LinkCandidateGoneReason.notAvailable,
        ),
        _ => const SelfScoreLoadException(_unreachable),
      };
    }
  }

  /// Runs a call to an account route. Unlike [_read], a refusal is never a
  /// guest session ending: the account token has its own life, and the pilot
  /// can still use their guest link.
  Future<T> _readAccount<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiHttpError catch (error) {
      // The answers of a link candidate keep their code for the caller.
      if (error.statusCode == 404 || error.statusCode == 409) rethrow;
      throw const SelfScoreLoadException(_unreachable);
    } on AuthTokenUnavailableException {
      throw const SelfScoreLoadException(_unreachable);
    } on ApiException {
      throw const SelfScoreLoadException(_unreachable);
    }
  }

  @override
  Future<TeamOverview> teamOverview(String contestId) async =>
      throw const SelfScoreLoadException(
        'The team overview is coming soon. Use the link from your contest '
        'director.',
      );

  @override
  Future<String> invitationLink() =>
      _read(() async => (await _client.participantInvitationLink()).link);

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
      lastOpenRound: entry.lastOpenRound,
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
      policy: OfficializationPolicy.fromWire(group.scoresBecomeOfficial?.json),
      preliminary: group.preliminary,
    );
  });

  GroupResultRow _groupRow(ParticipantGroupRowDto row) {
    final kind = switch (row.state) {
      ParticipantScoreState.zero => GroupRowKind.zero,
      ParticipantScoreState.notEntered ||
      ParticipantScoreState.draft => GroupRowKind.noScore,
      ParticipantScoreState.retired => GroupRowKind.retired,
      _ => GroupRowKind.scored,
    };
    final seconds = row.timeFlownSeconds;
    final height = row.launchHeight;
    final score = row.flightScore;
    return GroupResultRow(
      name: row.pilotName,
      pilotNumber: row.pilotNumber,
      kind: kind,
      time: seconds == null ? null : FlightTimeInput.format(seconds.toDouble()),
      height: height?.round(),
      landing: row.landingPoints,
      rawScore: row.rawScore == null ? null : ScoreFormat.score(row.rawScore!),
      // A missing score is not in the standings yet, so it gets no value even
      // when the server carries an estimate.
      score: kind == GroupRowKind.noScore || score == null
          ? null
          : ScoreFormat.score(score),
      zeroReason: row.zeroReason?.toLowerCase(),
      isYou: row.isYou,
      reviewPending: row.reviewPending,
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
          policy: OfficializationPolicy.fromWire(
            overall.scoresBecomeOfficial?.json,
          ),
          preliminary: overall.preliminary,
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
