import '../enums/discipline_type.dart';
import '../errors/contest_state_error.dart';
import '../errors/entity_not_found_error.dart';
import '../models/contest/contest_configuration_revision.dart';
import '../models/contest/core_options.dart';
import '../models/id.dart';
import '../models/matrix/round.dart';
import '../repositories/repository.dart';
import '../scoring/recalculation/f5j_recalculation.dart';
import '../scoring/recalculation/recalculate_f5j_contest.dart';
import 'f5j_results_input.dart';
import 'results_service.dart';

/// The F5J results of a contest as a participant sees them: official scores
/// plus pilots' submitted attempts, calculated now.
class PreliminaryCalculation {
  const PreliminaryCalculation({
    required this.revision,
    required this.rounds,
    required this.input,
    required this.recalculation,
  });

  final ContestConfigurationRevision revision;

  /// The current rounds, in round order.
  final List<Round> rounds;

  /// The flights that counted, with the attempts they came from.
  final F5jResultsInput input;

  /// Null while no round has a score.
  final F5jRecalculation? recalculation;

  /// The latest round with a score.
  int get latestRound => input.completedRounds;

  /// True when a score counted as of [round] is a pilot's attempt, or a round
  /// up to [round] still has a missing score.
  bool isPreliminaryAsOf(int round) =>
      input.isIncompleteAsOf(round) ||
      input.scored.any((s) => s.isPreliminary && s.round.ordinal <= round);
}

/// Calculates results for the participant views.
///
/// Official scores win; a flight with none counts on the pilot's newest
/// submitted attempt. The calculation uses the engine the director's results
/// use, runs on every read and stores nothing, so pilot-entered scores never
/// reach the stored results, the director's views or the public site.
class PreliminaryResultsService {
  PreliminaryResultsService(this.repository);

  final Repository repository;

  /// Throws an [EntityNotFoundError] for an unknown contest and a
  /// [ContestStateError] when the contest is not configured or not F5J.
  Future<PreliminaryCalculation> calculate(Id contestId) async {
    if (await repository.contestRepository.findById(contestId) == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    final revision = await repository.contestConfigurationRevisionRepository
        .latestForContest(contestId);
    if (revision == null) {
      throw ContestStateError(
        'not_configured',
        'the contest has no configuration yet',
      );
    }
    final profile = await repository.disciplineProfileRepository.findById(
      revision.disciplineProfileId,
    );
    if (profile?.profile.type != DisciplineType.f5j) {
      throw ContestStateError(
        'discipline_not_supported',
        'results are not available for this discipline yet',
      );
    }
    final rounds =
        (await repository.roundRepository.listForContest(contestId))
            .where((round) => round.isCurrent)
            .toList()
          ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    final options = CoreOptions.fromMap(revision.config.core);
    final input = await F5jResultsInput.build(
      repository,
      contestId: contestId,
      revision: revision,
      rounds: rounds,
      participations: await repository.contestParticipationRepository
          .listForContest(contestId),
      teamsEnabled: false,
      includePreliminaryAttempts: true,
    );
    return PreliminaryCalculation(
      revision: revision,
      rounds: rounds,
      input: input,
      recalculation: input.completedRounds == 0
          ? null
          : recalculateF5jContest(
              input.input,
              options: ResultsService.engineOptions(revision),
              completedRounds: input.completedRounds,
              dropAfterRounds: options.dropAfterRounds,
              tieBreakerEnabled: options.tiebreakerEnabled,
            ),
    );
  }
}
