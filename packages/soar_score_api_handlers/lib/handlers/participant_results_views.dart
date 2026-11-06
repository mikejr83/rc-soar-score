import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'participant_views.dart';

/// The participant results routes (#146): the pilot's group in a round and
/// the overall individual standings.
///
/// Both are calculated on read by [PreliminaryResultsService]: official
/// scores plus pilots' submitted attempts. Pilot-entered scores are
/// preliminary and are never stored as results, so these views are the only
/// place they are ranked.

/// The group the pilot flew in during round [roundOrdinal], or null when the
/// pilot has no flight in that round (also for a round that does not exist).
Future<ParticipantGroupResultsDto?> participantGroupResults(
  Repository repository,
  ParticipantAccess access,
  int roundOrdinal,
) async {
  final calculation = await PreliminaryResultsService(repository)
      .calculate(access.contestId);
  final round = calculation.rounds
      .where((round) => round.ordinal == roundOrdinal)
      .firstOrNull;
  if (round == null) return null;

  // One live flight per pilot, the highest flight sequence, as the results
  // count them.
  final byPilot = <Id, MatrixAssignment>{};
  for (final assignment
      in await repository.matrixAssignmentRepository.listLiveForRound(
        round.id,
      )) {
    final best = byPilot[assignment.contestParticipationId];
    if (best == null || assignment.flightSequence >= best.flightSequence) {
      byPilot[assignment.contestParticipationId] = assignment;
    }
  }
  final mine = byPilot[access.participation.id];
  if (mine == null) return null;

  final participations = {
    for (final p
        in await repository.contestParticipationRepository.listForContest(
          access.contestId,
        ))
      p.id: p,
  };
  final slots = {
    for (final slot in calculation.input.scored)
      if (slot.round.ordinal == roundOrdinal)
        slot.assignment.contestParticipationId: slot,
  };
  final flights = {
    for (final flight in calculation.recalculation?.flights ?? const [])
      if (flight.round == roundOrdinal) flight.pilotId: flight,
  };
  final landing = await _landingLabels(repository, calculation.revision);

  final rows = <({double? sortKey, ParticipantGroupRowDto row})>[];
  for (final assignment in byPilot.values) {
    if (assignment.group != mine.group) continue;
    final participation = participations[assignment.contestParticipationId];
    if (participation == null || !participation.isPilot) continue;
    final profile = await repository.participantProfileRepository.findById(
      participation.participantProfileId,
    );
    final name = [
      profile?.firstName,
      profile?.lastName,
    ].whereType<String>().join(' ');
    final slot = slots[participation.id];
    final flight = flights[participation.id.value];
    final retired = participation.hasRetiredBy(roundOrdinal);
    final components = slot?.components;
    final seconds = components?['time_flown'];
    final height = components?['launch_height'];
    final landingKey = components?['landing'];
    final zero = flight?.flight.outcome == FlightOutcome.zero;
    rows.add((
      sortKey: flight?.group.groupScore,
      row: ParticipantGroupRowDto(
        pilotName: name,
        pilotNumber: participation.participantNumber,
        state: retired
            ? ParticipantScoreState.retired
            : slot == null
            ? ParticipantScoreState.notEntered
            : zero
            ? ParticipantScoreState.zero
            : slot.isPreliminary
            ? ParticipantScoreState.submitted
            : ParticipantScoreState.official,
        isYou: participation.id == access.participation.id,
        isEstimate: false,
        timeFlownSeconds: seconds is num ? seconds.round() : null,
        launchHeight: height is num ? height : null,
        landing: landingKey == null
            ? null
            : landing[landingKey] ?? landingKey.toString(),
        flightScore: flight?.group.groupScore,
        rawScore: flight?.flight.rawScore,
        roundScore: flight?.group.groupScore,
        zeroReason: zero ? flight!.flight.zeroReasons.firstOrNull?.code : null,
      ),
    ));
  }
  rows.sort((a, b) {
    if (a.sortKey == null || b.sortKey == null) {
      if (a.sortKey == b.sortKey) {
        return a.row.pilotName.compareTo(b.row.pilotName);
      }
      return a.sortKey == null ? 1 : -1;
    }
    return b.sortKey!.compareTo(a.sortKey!);
  });

  final latest = calculation.latestRound;
  return ParticipantGroupResultsDto(
    round: roundOrdinal,
    group: participantGroupLabel(mine.group - 1),
    latestRound: latest < roundOrdinal ? roundOrdinal : latest,
    preliminary:
        rows.any(
          (r) =>
              r.sortKey == null ||
              r.row.state == ParticipantScoreState.submitted,
        ) ||
        calculation.input.incompleteGroups.contains((roundOrdinal, mine.group)),
    rows: [for (final r in rows) r.row],
  );
}

/// The overall individual standings as of [asOfRound] (the latest scored
/// round when null).
///
/// While the director hides overall results the standings are held at
/// `resultsHiddenThroughRound`: a later round is answered with the held
/// round and `held_at_round` says so. Returns null for a round that has no
/// scores.
Future<ParticipantOverallResultsDto?> participantOverallResults(
  Repository repository,
  ParticipantAccess access, {
  int? asOfRound,
}) async {
  final calculation = await PreliminaryResultsService(repository)
      .calculate(access.contestId);
  final latest = calculation.latestRound;
  final held = access.contest.resultsHiddenThroughRound;
  // A round nobody scored is not found, unless the hidden-results cap
  // answers it with the held round.
  if (asOfRound != null &&
      (asOfRound < 1 || (asOfRound > latest && held == null))) {
    return null;
  }
  var round = asOfRound ?? latest;
  if (held != null && round > held) round = held;
  if (round > latest) round = latest;

  final recalculation = calculation.recalculation;
  if (recalculation == null || round < 1) {
    return ParticipantOverallResultsDto(
      asOfRound: 0,
      latestRound: latest,
      heldAtRound: held,
      preliminary: true,
      standings: const [],
    );
  }
  final standing = recalculation.standings.firstWhere(
    (s) => s.asOfRound == round,
  );
  final scores = {
    for (final total in standing.totals) total.pilotId: total.overallScore,
  };
  final participations = {
    for (final p
        in await repository.contestParticipationRepository.listForContest(
          access.contestId,
        ))
      p.id.value: p,
  };
  final lines = <ParticipantStandingDto>[];
  for (final place in standing.ranking.places) {
    final participation = participations[place.pilotId];
    if (participation == null) continue;
    final profile = await repository.participantProfileRepository.findById(
      participation.participantProfileId,
    );
    lines.add(
      ParticipantStandingDto(
        place: place.place,
        pilotName: [
          profile?.firstName,
          profile?.lastName,
        ].whereType<String>().join(' '),
        pilotNumber: participation.participantNumber,
        score: scores[place.pilotId] ?? 0,
        isYou: participation.id == access.participation.id,
        tied: place.isTied,
      ),
    );
  }
  lines.sort((a, b) => a.place.compareTo(b.place));
  final you = lines.where((l) => l.isYou).firstOrNull;
  return ParticipantOverallResultsDto(
    asOfRound: round,
    latestRound: latest,
    heldAtRound: held,
    preliminary:
        standing.ranking.isPreliminary || calculation.isPreliminaryAsOf(round),
    yourPlace: you?.place,
    yourScore: you?.score,
    standings: lines,
  );
}

Future<Map<String, String>> _landingLabels(
  Repository repository,
  ContestConfigurationRevision revision,
) async {
  final tableId = revision.landingTableId;
  final table = tableId == null
      ? null
      : await repository.landingTableRepository.findById(tableId);
  return {
    for (final result in table?.results ?? const <LandingResult>[])
      result.entryKey: result.displayValue,
  };
}
