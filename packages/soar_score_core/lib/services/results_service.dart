import '../enums/discipline_type.dart';
import '../enums/flight_outcome.dart';
import '../errors/contest_state_error.dart';
import '../errors/entity_not_found_error.dart';
import '../models/contest/contest.dart';
import '../models/contest/contest_configuration_revision.dart';
import '../models/contest/core_options.dart';
import '../models/id.dart';
import '../models/matrix/matrix_revision.dart';
import '../models/matrix/round.dart';
import '../models/results/flight_result.dart';
import '../models/results/participation_standing.dart';
import '../models/results/provenance.dart';
import '../models/results/team_standing.dart';
import '../repositories/repository.dart';
import '../scoring/recalculation/calculation_version.dart';
import '../scoring/recalculation/f5j_recalculation.dart';
import '../scoring/recalculation/recalculate_f5j_contest.dart';
import 'contest_results.dart';
import 'f5j_results_input.dart';
import 'round_flight_result.dart';
import 'round_results.dart';

/// Calculates and serves the results of a contest: flight results, pilot
/// standings and team standings.
///
/// The results are derived data. [recalculate] rebuilds all of them from the
/// official scores under the current configuration and matrix, and stamps
/// each row with the revisions and calculation version it was computed under.
/// The reads flag results as stale when those stamps, or the latest official
/// score, no longer match.
///
/// Only F5J is calculated so far.
class ResultsService {
  ResultsService(
    this.repository, {
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create;

  final Repository repository;
  final DateTime Function() _clock;
  final Id Function() _newId;

  /// The standings as of the latest scored round.
  ///
  /// Throws an [EntityNotFoundError] when the contest does not exist.
  Future<ContestResults> read(Id contestId) async {
    final contest = await _requireContest(contestId);
    final stored = await repository.participationStandingRepository
        .listForContest(contestId);
    if (stored.isEmpty) {
      return ContestResults(isStale: await _hasScores(contest));
    }
    final latest = stored.map((s) => s.asOfRound).reduce(_max);
    final standings = [
      for (final standing in stored)
        if (standing.asOfRound == latest) standing,
    ]..sort((a, b) => a.place.compareTo(b.place));
    final teams = [
      ...await repository.teamStandingRepository.listAsOfRound(
        contestId,
        latest,
      ),
    ]..sort((a, b) => a.place.compareTo(b.place));
    return ContestResults(
      asOfRound: latest,
      isStale: await _isStale(
        contest,
        stamps: ResultStamps(
          configRevisionId: standings.first.configRevisionId,
          matrixRevisionId: standings.first.matrixRevisionId,
          calculationVersion: standings.first.calculationVersion,
        ),
        computedAt: standings.first.computedAt,
      ),
      standings: standings,
      teams: teams,
    );
  }

  /// The calculated flights of the round with [ordinal], by group.
  ///
  /// Throws an [EntityNotFoundError] when the contest or round does not
  /// exist.
  Future<RoundResults> round(Id contestId, int ordinal) async {
    final contest = await _requireContest(contestId);
    final round = (await _currentRounds(contestId))
        .where((round) => round.ordinal == ordinal)
        .firstOrNull;
    if (round == null) {
      throw ArgumentError.value(ordinal, 'ordinal', 'no such round');
    }
    final groupOf = {
      for (final assignment
          in await repository.matrixAssignmentRepository.listLiveForRound(
            round.id,
          ))
        assignment.id: assignment.group,
    };
    final placeholders = {
      for (final placeholder
          in await repository.scorePlaceholderRepository.listForContest(
            contestId,
          ))
        placeholder.id: placeholder,
    };
    final flights = <RoundFlightResult>[];
    FlightResult? first;
    for (final result in await repository.flightResultRepository.listForContest(
      contestId,
    )) {
      if (result.creditedRoundId != round.id) continue;
      final group =
          groupOf[placeholders[result.scorePlaceholderId]?.assignmentId];
      if (group == null) continue;
      first ??= result;
      flights.add(RoundFlightResult(group: group, result: result));
    }
    flights.sort((a, b) {
      final byGroup = a.group.compareTo(b.group);
      return byGroup != 0
          ? byGroup
          : b.result.groupScore.compareTo(a.result.groupScore);
    });
    return RoundResults(
      ordinal: ordinal,
      isStale: first == null
          ? await _hasScores(contest)
          : await _isStale(
              contest,
              stamps: ResultStamps(
                configRevisionId: first.configRevisionId,
                matrixRevisionId: first.matrixRevisionId,
                calculationVersion: first.calculationVersion,
              ),
              computedAt: first.computedAt,
            ),
      flights: flights,
    );
  }

  /// Recalculates every result of the contest from its official scores and
  /// stores them in place of the earlier ones, then returns the standings.
  ///
  /// A contest with no matrix yet, or no scores, ends with no results.
  /// Throws a [ContestStateError] when the contest has no configuration or
  /// is not an F5J contest.
  Future<ContestResults> recalculate(Id contestId) async {
    final contest = await _requireContest(contestId);
    final revision = await repository.contestConfigurationRevisionRepository
        .latestForContest(contestId);
    if (revision == null) {
      throw ContestStateError(
        'not_configured',
        'the contest has no configuration yet',
      );
    }
    await _requireF5j(revision);
    final matrix = await _currentMatrixRevision(contestId);
    if (matrix == null) {
      await _store(contestId, const [], const [], const []);
      return read(contest.id);
    }

    final options = CoreOptions.fromMap(revision.config.core);
    final built = await F5jResultsInput.build(
      repository,
      contestId: contestId,
      revision: revision,
      rounds: await _currentRounds(contestId),
      participations: await repository.contestParticipationRepository
          .listForContest(contestId),
      teamsEnabled: options.teamsEnabled,
    );
    if (built.completedRounds == 0) {
      await _store(contestId, const [], const [], const []);
      return read(contest.id);
    }

    final calculation = recalculateF5jContest(
      built.input,
      options: _engineOptions(revision),
      completedRounds: built.completedRounds,
      dropAfterRounds: options.dropAfterRounds,
      tieBreakerEnabled: options.tiebreakerEnabled,
      teamPilotCount: options.teamPilotCount,
    );

    final now = _clock();
    final stamps = _Stamps(revision.id, matrix.id, calculation, now);
    await _store(
      contestId,
      _flightResults(contestId, built, calculation, stamps),
      _standings(contestId, built, calculation, stamps),
      _teamStandings(contestId, built, calculation, stamps),
    );
    return read(contestId);
  }

  List<FlightResult> _flightResults(
    Id contestId,
    F5jResultsInput built,
    F5jRecalculation calculation,
    _Stamps stamps,
  ) {
    final slots = {for (final slot in built.scored) _key(slot): slot};
    return [
      for (final flight in calculation.flights)
        if (slots[(flight.round, flight.pilotId)] case final slot?)
          FlightResult(
            id: _newId(),
            contestId: contestId,
            scorePlaceholderId: slot.placeholder.id,
            officialScoreId: slot.officialScore.id,
            contestParticipationId: slot.assignment.contestParticipationId,
            creditedRoundId: slot.assignment.creditedRoundId,
            outcome: flight.flight.outcome,
            rawPoints: flight.flight.rawScore,
            landingPoints: flight.flight.outcome == FlightOutcome.scored
                ? flight.flight.landingBonus
                : null,
            flightPenaltyPoints: flight.flight.flightPenalty,
            groupScore: flight.group.groupScore,
            isPreliminary: built.incompleteGroups.contains((
              flight.round,
              slot.group,
            )),
            configRevisionId: stamps.configRevisionId,
            matrixRevisionId: stamps.matrixRevisionId,
            calculationVersion: stamps.calculationVersion,
            computedAt: stamps.computedAt,
          ),
    ];
  }

  (int, String) _key(ScoredSlot slot) =>
      (slot.round.ordinal, slot.assignment.contestParticipationId.value);

  List<ParticipationStanding> _standings(
    Id contestId,
    F5jResultsInput built,
    F5jRecalculation calculation,
    _Stamps stamps,
  ) => [
    for (final standing in calculation.standings)
      for (final total in standing.totals)
        if (standing.ranking.places
                .where((place) => place.pilotId == total.pilotId)
                .firstOrNull
            case final place?)
          ParticipationStanding(
            id: _newId(),
            contestId: contestId,
            contestParticipationId: Id.parse(total.pilotId),
            asOfRound: standing.asOfRound,
            place: place.place,
            isTied: place.isTied,
            rawTotal: total.rawTotal,
            droppedRounds: total.droppedRounds,
            penaltyTotal: total.penaltyTotal,
            overallScore: total.overallScore,
            isPreliminary:
                total.isPreliminary ||
                standing.ranking.isPreliminary ||
                built.isIncompleteAsOf(standing.asOfRound),
            configRevisionId: stamps.configRevisionId,
            matrixRevisionId: stamps.matrixRevisionId,
            calculationVersion: stamps.calculationVersion,
            computedAt: stamps.computedAt,
          ),
  ];

  List<TeamStanding> _teamStandings(
    Id contestId,
    F5jResultsInput built,
    F5jRecalculation calculation,
    _Stamps stamps,
  ) => [
    for (final standing in calculation.standings)
      for (final team in standing.teams)
        TeamStanding(
          id: _newId(),
          contestId: contestId,
          teamId: Id.parse(team.teamId),
          asOfRound: standing.asOfRound,
          place: team.place,
          isTied: team.isTied,
          teamScore: team.total,
          countedParticipations: [
            for (final pilot in team.countedPilotIds) Id.parse(pilot),
          ],
          isPreliminary:
              team.isPreliminary || built.isIncompleteAsOf(standing.asOfRound),
          configRevisionId: stamps.configRevisionId,
          matrixRevisionId: stamps.matrixRevisionId,
          calculationVersion: stamps.calculationVersion,
          computedAt: stamps.computedAt,
        ),
  ];

  Future<void> _store(
    Id contestId,
    List<FlightResult> flights,
    List<ParticipationStanding> standings,
    List<TeamStanding> teams,
  ) => repository.flightResultRepository.replaceResultsForContest(
    contestId: contestId,
    flights: flights,
    standings: standings,
    teamStandings: teams,
  );

  /// The engine's options: the discipline settings plus the core settings
  /// that shape the group score.
  Map<String, Object?> _engineOptions(ContestConfigurationRevision revision) =>
      {
        for (final key in const [
          'group_score_mode',
          'rounding_mode',
          'decimal_places',
        ])
          if (revision.config.core[key] != null) key: revision.config.core[key],
        ...revision.config.discipline,
      };

  Future<void> _requireF5j(ContestConfigurationRevision revision) async {
    final profile = await repository.disciplineProfileRepository.findById(
      revision.disciplineProfileId,
    );
    if (profile == null) {
      throw EntityNotFoundError(
        entityType: 'DisciplineProfile',
        entityId: revision.disciplineProfileId,
      );
    }
    if (profile.profile.type != DisciplineType.f5j) {
      throw ContestStateError(
        'discipline_not_supported',
        'results are not available for ${profile.profile.name} yet',
      );
    }
  }

  Future<bool> _isStale(
    Contest contest, {
    required ResultStamps stamps,
    required DateTime computedAt,
  }) async {
    final revision = await repository.contestConfigurationRevisionRepository
        .latestForContest(contest.id);
    final matrix = await _currentMatrixRevision(contest.id);
    if (revision == null || matrix == null) return true;
    if (stamps.isStale(
      ResultStamps(
        configRevisionId: revision.id,
        matrixRevisionId: matrix.id,
        calculationVersion: f5jCalculationVersion,
      ),
    )) {
      return true;
    }
    return _latestScoreAt(contest.id, after: computedAt);
  }

  /// Whether the contest has an official score at all.
  Future<bool> _hasScores(Contest contest) =>
      _latestScoreAt(contest.id, after: null);

  /// Whether an official score was set after [after], or at all when null.
  Future<bool> _latestScoreAt(Id contestId, {required DateTime? after}) async {
    for (final placeholder
        in await repository.scorePlaceholderRepository.listForContest(
          contestId,
        )) {
      final official = await repository.officialScoreRepository
          .currentForPlaceholder(placeholder.id);
      if (official == null) continue;
      if (after == null || official.setAt.isAfter(after)) return true;
    }
    return false;
  }

  Future<MatrixRevision?> _currentMatrixRevision(Id contestId) async {
    final finalized = (await repository.matrixRevisionRepository.listForContest(
      contestId,
    )).where((r) => r.isFinalized).toList();
    return finalized.isEmpty ? null : finalized.last;
  }

  Future<List<Round>> _currentRounds(Id contestId) async =>
      (await repository.roundRepository.listForContest(contestId))
          .where((round) => round.isCurrent)
          .toList()
        ..sort((a, b) => a.ordinal.compareTo(b.ordinal));

  Future<Contest> _requireContest(Id contestId) async {
    final contest = await repository.contestRepository.findById(contestId);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    return contest;
  }

  static int _max(int a, int b) => a > b ? a : b;
}

class _Stamps {
  _Stamps(
    this.configRevisionId,
    this.matrixRevisionId,
    F5jRecalculation c,
    this.computedAt,
  ) : calculationVersion = c.calculationVersion;

  final Id configRevisionId;
  final Id matrixRevisionId;
  final String calculationVersion;
  final DateTime computedAt;
}
