import '../errors/entity_not_found_error.dart';
import '../models/contest/contest.dart';
import '../models/id.dart';
import '../repositories/repository.dart';
import 'contest_results.dart';
import 'matrix/matrix_service.dart';
import 'report_data.dart';
import 'results_service.dart';
import 'round_results.dart';
import 'scores_service.dart';

/// Which parts of [ReportData] a request wants.
class ReportInclude {
  const ReportInclude({
    this.facts = true,
    this.scores = false,
    this.asOfRound,
    this.rounds = const [],
  });

  /// Contest, configuration, participations, participants, teams,
  /// memberships, matrix and scores: what every report needs.
  final bool facts;

  /// The official scores alone, for a caller that holds the facts already.
  final bool scores;

  /// The stored standings as of this round, when asked for.
  final int? asOfRound;

  /// The rounds whose flight results are asked for.
  final List<int> rounds;

  bool get standings => asOfRound != null || rounds.isNotEmpty;
}

/// Reads what a report needs about a contest in one call, so a phone on a
/// poor connection makes one request instead of eight to fourteen.
///
/// It composes the same services the separate endpoints use, so the content
/// is the same as theirs. The reads run one after another inside a single
/// request; there is no read transaction, so a score saved while the request
/// runs can show in one part and not another, exactly as with separate
/// requests but over a much shorter window.
class ReportDataService {
  ReportDataService(Repository repository)
    : _repository = repository,
      _scores = ScoresService(repository),
      _results = ResultsService(repository),
      _matrix = MatrixService(repository);

  final Repository _repository;
  final ScoresService _scores;
  final ResultsService _results;
  final MatrixService _matrix;

  /// Throws an [EntityNotFoundError] when the contest does not exist. An
  /// [ArgumentError] from a round that does not exist reaches the caller as
  /// it does on the per-round endpoint.
  Future<ReportData> read(Id contestId, {ReportInclude? include}) async {
    final want = include ?? const ReportInclude();
    final contest = await _repository.contestRepository.findById(contestId);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    if (!want.facts) {
      return ReportData(
        contest: contest,
        scores: want.scores ? await _scores.list(contestId) : null,
        results: await _standing(contestId, want),
        roundResults: await _rounds(contestId, want),
      );
    }
    return _facts(contest, want);
  }

  Future<ReportData> _facts(Contest contest, ReportInclude want) async {
    final id = contest.id;
    final participations = await _repository.contestParticipationRepository
        .listForContest(id);
    final profiles = await _repository.participantProfileRepository.findByIds({
      for (final participation in participations)
        participation.participantProfileId,
    });
    return ReportData(
      contest: contest,
      configuration: await _repository.contestConfigurationRevisionRepository
          .latestForContest(id),
      participations: participations,
      participants: profiles.values.toList(),
      teams: await _repository.teamRepository.listForContest(id),
      teamMemberships: await _repository.teamMembershipRepository
          .listForContest(id),
      matrix: await _matrix.current(id),
      scores: await _scores.list(id),
      results: await _standing(id, want),
      roundResults: await _rounds(id, want),
    );
  }

  /// The stored standing as of the asked round; `null` when none is stored.
  Future<ContestResults?> _standing(Id id, ReportInclude want) async {
    final asOf = want.asOfRound;
    if (asOf == null) {
      return null;
    }
    try {
      return await _results.read(id, asOfRound: asOf);
    } on ArgumentError {
      return null;
    }
  }

  Future<List<RoundResults>?> _rounds(Id id, ReportInclude want) async {
    if (want.rounds.isEmpty) {
      return null;
    }
    return [for (final round in want.rounds) await _results.round(id, round)];
  }
}
