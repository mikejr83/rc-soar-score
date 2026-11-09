import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// What the participant read routes (#787) answer. Built from the stored
/// contest for one [ParticipantAccess] only: every read is scoped to the
/// access's own participation, so nothing about another pilot is reachable.

/// The contest and pilot of [access], as the invitation link opens and the
/// session check answer.
Future<({ParticipantContestDto contest, ParticipantLinkDto participant})>
participantContext(Repository repository, ParticipantAccess access) async {
  final profile = await repository.participantProfileRepository.findById(
    access.participation.participantProfileId,
  );
  final contest = access.contest;
  final teamName = await _teamNameOf(repository, access);
  final matrix = await _CurrentRounds.load(repository, contest.id);
  final revision = await repository.contestConfigurationRevisionRepository
      .latestForContest(contest.id);
  final disciplineProfile = revision == null
      ? null
      : await repository.disciplineProfileRepository.findById(
          revision.disciplineProfileId,
        );
  final scoring = access.readOnly
      ? 'read_only'
      : contest.scoringAccess == ScoringAccess.open &&
            contest.adminLock == AdminLock.unlocked
      ? 'open'
      : 'closed';
  return (
    contest: ParticipantContestDto(
      contestId: contest.id,
      name: contest.name,
      disciplineType: _disciplineText[disciplineProfile?.profile.type] ?? '',
      lifecycle: switch (contest.lifecycleState) {
        LifecycleState.completed => 'Completed',
        LifecycleState.running => 'Running',
        _ => 'Ready',
      },
      scoringAccess: scoring,
      roundCount: matrix.rounds.length,
      timeZone: contest.timezone,
    ),
    participant: ParticipantLinkDto(
      participationId: access.participation.id,
      pilotName: [
        profile?.firstName,
        profile?.lastName,
      ].whereType<String>().join(' '),
      pilotNumber: access.participation.participantNumber,
      role: 'pilot',
      teamName: teamName,
    ),
  );
}

/// The name of the team the pilot is on, or null when they are on none.
Future<String?> _teamNameOf(
  Repository repository,
  ParticipantAccess access,
) async {
  final memberships = await repository.teamMembershipRepository.listForContest(
    access.contest.id,
  );
  final membership = memberships
      .where((m) => m.contestParticipationId == access.participation.id)
      .firstOrNull;
  if (membership == null) return null;
  return (await repository.teamRepository.findById(membership.teamId))?.name;
}

/// The pilot's overview: their own flight in every current round, the score
/// state of each, and the next round to score.
///
/// The next target is the first round, in round order, whose flight has no
/// score yet and which the pilot has not retired before. The contest has no
/// option to relax sequential entry, so the target is also the only round
/// the submit service (#144) accepts.
Future<ParticipantOverviewDto> participantOverview(
  Repository repository,
  ParticipantAccess access,
) async {
  final context = await participantContext(repository, access);
  final flights = await _pilotFlights(repository, access);
  final rounds = <ParticipantRoundDto>[];
  var nextFound = false;
  for (final flight in flights.flights) {
    final next = !nextFound && flight.state == ParticipantScoreState.notEntered;
    nextFound |= next;
    rounds.add(flight.toDto(isNextToScore: next));
  }
  return ParticipantOverviewDto(
    contest: context.contest,
    participant: context.participant,
    matrixRevision: flights.matrixRevision,
    access: _accessOf(access),
    rounds: rounds,
  );
}

/// What the entry form needs for round [roundOrdinal] of the pilot, or null
/// when the pilot has no flight in that round (also for a round that does
/// not exist, so the two cannot be told apart).
Future<ParticipantEntryContextDto?> participantEntryContext(
  Repository repository,
  ParticipantAccess access,
  int roundOrdinal,
) async {
  final flights = await _pilotFlights(repository, access);
  final flight = flights.flights
      .where((f) => f.ordinal == roundOrdinal)
      .firstOrNull;
  if (flight == null) return null;
  final revision = await repository.contestConfigurationRevisionRepository
      .latestForContest(access.contestId);
  if (revision == null) return null;
  final disciplineProfile = await repository.disciplineProfileRepository
      .findById(revision.disciplineProfileId);
  if (disciplineProfile?.profile.type != DisciplineType.f5j) {
    // Score entry is F5J only so far, as on the director's route.
    throw ContestStateError(
      'discipline_not_supported',
      'self-scoring is not available for this discipline yet',
    );
  }
  final profile = F5jProfile();
  final options = profile.options(revision.config.discipline);
  final allowsRestart =
      options.motorRestartMode != F5jMotorRestartMode.notAllowed;
  final table = revision.landingTableId == null
      ? null
      : await repository.landingTableRepository.findById(
          revision.landingTableId!,
        );
  final hasScore =
      flight.state != ParticipantScoreState.notEntered &&
      flight.state != ParticipantScoreState.draft;
  return ParticipantEntryContextDto(
    submittedScore: hasScore
        ? await _submittedScore(repository, access, flight)
        : null,
    assignmentId: flight.assignmentId,
    round: flight.ordinal,
    roundCount: flights.roundCount,
    group: flight.group,
    lane: flight.lane,
    taskType: null,
    matrixRevision: flights.matrixRevision,
    scoreRevision: flight.scoreRevision,
    rulesVersion: '${profile.discipline.name}-${profile.rulesVersion}',
    state: flight.state,
    allowsMotorRestart: allowsRestart,
    fields: [
      for (final field in profile.fields)
        // Derived values are the server's to work out, and the cumulative
        // penalty is the director's alone.
        if (field.acceptedInSubmission &&
            field.id != 'cumulative_penalty' &&
            (allowsRestart || field.id != 'motor_restart'))
          _field(field, fractionalSeconds: options.duration.timeDecimals),
    ],
    landingTable: [
      for (final result in table?.results ?? const <LandingResult>[])
        LandingOptionDto(
          id: result.entryKey,
          label: result.displayValue,
          points: result.pointValue,
        ),
    ],
  );
}

/// What the flight's score holds, so the entry form can show it read-only.
/// Calculated on read with the group results, because a pilot's own score is
/// preliminary and not stored as a result. Null when the calculation has no
/// score for the flight (a retired or locked flight with nothing entered).
Future<ParticipantScoreDto?> _submittedScore(
  Repository repository,
  ParticipantAccess access,
  _Flight flight,
) async {
  final calculation = await PreliminaryResultsService(repository)
      .calculate(access.contestId);
  final slot = calculation.input.scored
      .where(
        (s) =>
            s.round.ordinal == flight.ordinal &&
            s.assignment.contestParticipationId == access.participation.id,
      )
      .firstOrNull;
  if (slot == null) return null;
  final result = (calculation.recalculation?.flights ?? const [])
      .where(
        (f) =>
            f.round == flight.ordinal &&
            f.pilotId == access.participation.id.value,
      )
      .firstOrNull;
  return ParticipantScoreDto(
    assignmentId: flight.assignmentId,
    round: flight.ordinal,
    state: flight.state,
    revision: flight.scoreRevision,
    components: slot.components,
    enteredBy: flight.enteredBy ?? '',
    enteredAt:
        flight.enteredAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    flightScore: result?.group.groupScore,
    rawScore: result?.flight.rawScore,
    roundScore: result?.group.groupScore,
  );
}

ScoreFieldDto _field(
  ScoringFieldDefinition field, {
  required int fractionalSeconds,
}) => ScoreFieldDto(
  key: field.id,
  label: field.label,
  type: switch (field.type) {
    ScoreFieldType.time => 'seconds',
    ScoreFieldType.int => 'integer',
    ScoreFieldType.landing => 'landing',
    ScoreFieldType.bool => 'boolean',
    _ => field.type.name,
  },
  required: field.required,
  unit: field.unit,
  precision: field.type == ScoreFieldType.time
      ? fractionalSeconds
      : field.precision,
  min: field.min,
  max: field.max,
);

ParticipantAccessDto _accessOf(ParticipantAccess access) {
  final contest = access.contest;
  if (access.readOnly) {
    return const ParticipantAccessDto(
      code: 'contest_completed',
      message: 'This contest is complete. Scores can be read, not entered.',
    );
  }
  if (access.participation.retiredAtRound != null) {
    return const ParticipantAccessDto(code: 'retired');
  }
  if (contest.adminLock != AdminLock.unlocked) {
    return const ParticipantAccessDto(code: 'locked');
  }
  if (contest.scoringAccess != ScoringAccess.open) {
    return const ParticipantAccessDto(code: 'scoring_closed');
  }
  return const ParticipantAccessDto(code: 'open');
}

/// The pilot's flight in each current round of the current matrix, by the
/// round it is credited to.
///
/// A late add can be flown in a later round and credited to an earlier one,
/// and a re-flight is scored in the round it replaces, so a flight belongs
/// to its `creditedRoundId`, as in the results. The group and lane are
/// where it is flown. When a round has several live flights of the pilot,
/// the highest flight sequence is the one that counts.
Future<_PilotFlights> _pilotFlights(
  Repository repository,
  ParticipantAccess access,
) async {
  final matrix = await _CurrentRounds.load(repository, access.contestId);
  final participation = access.participation;
  final scheduled = {for (final round in matrix.rounds) round.id};
  final byCredited = <Id, MatrixAssignment>{};
  for (final assignment
      in await repository.matrixAssignmentRepository.listForParticipation(
        participation.id,
      )) {
    if (assignment.isSuperseded ||
        !scheduled.contains(assignment.scheduledRoundId)) {
      continue;
    }
    final best = byCredited[assignment.creditedRoundId];
    if (best == null || assignment.flightSequence >= best.flightSequence) {
      byCredited[assignment.creditedRoundId] = assignment;
    }
  }
  final placeholders = {
    for (final placeholder
        in await repository.scorePlaceholderRepository.listForParticipation(
          participation.id,
        ))
      placeholder.assignmentId: placeholder,
  };
  final profile = await repository.participantProfileRepository.findById(
    participation.participantProfileId,
  );
  final pilotName = [
    profile?.firstName,
    profile?.lastName,
  ].whereType<String>().join(' ');

  // The scores of every flight, in three reads whatever the round count.
  final placeholderIds = [
    for (final assignment in byCredited.values)
      if (placeholders[assignment.id] case final placeholder?) placeholder.id,
  ];
  final officials = await repository.officialScoreRepository
      .currentForPlaceholders(placeholderIds);
  final latestAttempts = await repository.scoreAttemptRepository
      .latestForPlaceholders(placeholderIds);
  final attempts = await repository.scoreAttemptRepository.findByIds([
    for (final official in officials.values) official.scoreAttemptId,
  ]);

  final flights = <_Flight>[];
  for (final round in matrix.rounds) {
    final assignment = byCredited[round.id];
    if (assignment == null) continue;
    final placeholder = placeholders[assignment.id];
    final groups =
        matrix.groups[assignment.scheduledRoundId] ?? const <RoundGroup>[];
    final groupLocked = groups.any(
      (g) => g.groupNumber == assignment.group && g.isLocked,
    );
    final official = placeholder == null ? null : officials[placeholder.id];
    final attempt = official != null
        ? attempts[official.scoreAttemptId]
        : placeholder == null || placeholder.scoreRevision == 0
        ? null
        : latestAttempts[placeholder.id];
    flights.add(
      _Flight(
        ordinal: round.ordinal,
        assignment: assignment,
        placeholder: placeholder,
        state: participation.hasRetiredBy(round.ordinal)
            ? ParticipantScoreState.retired
            : _stateOf(placeholder, groupLocked: groupLocked),
        // The pilot's own entry carries their name, which the app shows as
        // "you"; anyone else is named by role, never by account.
        enteredBy: switch (attempt?.authority) {
          null => null,
          Authority.participant => pilotName,
          Authority.helper => 'Helper',
          _ => 'Director',
        },
        enteredAt: attempt?.acceptedAt ?? official?.setAt,
      ),
    );
  }
  return _PilotFlights(
    flights: flights,
    roundCount: matrix.rounds.length,
    matrixRevision: matrix.revisionNumber,
  );
}

ParticipantScoreState _stateOf(
  ScorePlaceholder? placeholder, {
  required bool groupLocked,
}) {
  if (placeholder == null) {
    return groupLocked
        ? ParticipantScoreState.locked
        : ParticipantScoreState.notEntered;
  }
  if (placeholder.isLocked) return ParticipantScoreState.locked;
  return switch (placeholder.state) {
    ScorePlaceholderState.notEntered =>
      groupLocked
          ? ParticipantScoreState.locked
          : ParticipantScoreState.notEntered,
    ScorePlaceholderState.submitted => ParticipantScoreState.submitted,
    ScorePlaceholderState.inReview => ParticipantScoreState.underReview,
    ScorePlaceholderState.official => ParticipantScoreState.official,
  };
}

class _PilotFlights {
  const _PilotFlights({
    required this.flights,
    required this.roundCount,
    required this.matrixRevision,
  });

  final List<_Flight> flights;
  final int roundCount;
  final int matrixRevision;
}

class _Flight {
  const _Flight({
    required this.ordinal,
    required this.assignment,
    required this.placeholder,
    required this.state,
    required this.enteredBy,
    required this.enteredAt,
  });

  final int ordinal;
  final MatrixAssignment assignment;
  final ScorePlaceholder? placeholder;
  final ParticipantScoreState state;
  final String? enteredBy;
  final DateTime? enteredAt;

  Id get assignmentId => assignment.id;
  String get group => participantGroupLabel(assignment.group - 1);
  int? get lane => assignment.lane;
  int get scoreRevision => placeholder?.scoreRevision ?? 0;

  ParticipantRoundDto toDto({required bool isNextToScore}) =>
      ParticipantRoundDto(
        round: ordinal,
        group: group,
        lane: lane,
        assignmentId: assignmentId,
        state: state,
        isNextToScore: isNextToScore,
        enteredBy: enteredBy,
        enteredAt: enteredAt,
        scoreRevision: scoreRevision,
      );
}

/// A, B, … Z, AA, AB, …: the group letters the pilot cards print.
String participantGroupLabel(int index) {
  var n = index;
  var label = '';
  do {
    label = String.fromCharCode(0x41 + n % 26) + label;
    n = n ~/ 26 - 1;
  } while (n >= 0);
  return label;
}

/// The current rounds of the latest finalized matrix, in round order, with
/// their groups.
class _CurrentRounds {
  const _CurrentRounds(this.rounds, this.groups, this.revisionNumber);

  final List<Round> rounds;
  final Map<Id, List<RoundGroup>> groups;
  final int revisionNumber;

  static Future<_CurrentRounds> load(
    Repository repository,
    Id contestId,
  ) async {
    final finalized = (await repository.matrixRevisionRepository.listForContest(
      contestId,
    )).where((revision) => revision.isFinalized).toList();
    if (finalized.isEmpty) return const _CurrentRounds([], {}, 0);
    final rounds =
        (await repository.roundRepository.listForContest(contestId))
            .where((round) => round.isCurrent)
            .toList()
          ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    final byRound = <Id, List<RoundGroup>>{};
    for (final group in await repository.roundGroupRepository.listForContest(
      contestId,
    )) {
      byRound.putIfAbsent(group.roundId, () => []).add(group);
    }
    return _CurrentRounds(rounds, byRound, finalized.last.revisionNumber);
  }
}

const _disciplineText = {
  DisciplineType.ales: 'ALES',
  DisciplineType.thermalDuration: 'ThermalDuration',
  DisciplineType.f3j: 'F3J',
  DisciplineType.f5j: 'F5J',
  DisciplineType.f3l: 'F3L',
  DisciplineType.f3k: 'F3K',
};
