import 'package:logging/logging.dart';

import '../../errors/contest_state_error.dart';
import '../../models/id.dart';
import '../../repositories/repository.dart';
import '../results_service.dart';
import '../scores_service.dart';

final _logger = Logger('RecalculationService');

/// Runs the automatic officialization of one contest.
typedef OfficializeContest = Future<AutomaticOfficialization> Function(
  Id contestId,
);

/// Runs the recalculation that follows a score entry, with a single retry.
///
/// The score entry and the recalculation are separate transactions: the
/// entry must not be rolled back when the recalculation fails, so the
/// handler catches the failure, retries once, and, if it still fails, leaves
/// the results stale and reports a warning on the entry response (ticket
/// 297). This class owns only the retry-and-report behaviour; the actual
/// calculation is [ResultsService.recalculate].
///
/// A [ContestStateError] is a refusal, not a transient failure: it is not
/// retried, but is reported as a warning because the score entry has already
/// been committed.
///
/// A service made with [RecalculationService.automatic] first runs the
/// automatic officialization (the contest's "Scores become official"
/// setting) for the contest, because every change that triggers a
/// recalculation can also complete a round or a group: a director's score
/// write, a retirement or assignment change, a change of the setting, an
/// accepted sync. When that run made scores official it recalculated in the
/// same transaction, so no second recalculation follows. A run that fails or
/// is refused never fails the caller's change and never blocks the plain
/// recalculation; the evaluation repeats on the next trigger or when the
/// server starts ([ScoresService.recoverAutomaticOfficialization]).
class RecalculationService {
  RecalculationService(this._results, {this.officialize});

  /// A service over [repository] that officializes automatically before it
  /// recalculates.
  factory RecalculationService.automatic(Repository repository) {
    final scores = ScoresService(repository);
    return RecalculationService(
      ResultsService(repository),
      officialize: scores.officializeAndRecalculate,
    );
  }

  final ResultsService _results;

  /// Runs the automatic officialization first; null for none.
  final OfficializeContest? officialize;

  /// Recalculates the results of [contestId] after a score entry.
  ///
  /// Returns `null` when the recalculation succeeded (possibly after one
  /// retry), or a warning string when recalculation fails or is refused.
  /// The score that triggered it is already stored in both cases; the results
  /// read as stale until a later recalculation succeeds.
  ///
  /// [cause] names what triggered it, for the warning and the log (a score
  /// entry by default; a retirement change uses its own).
  Future<String?> recalculateAfterEntry(
    Id contestId, {
    String cause = 'a score entry',
  }) async {
    final officialize = this.officialize;
    if (officialize != null) {
      try {
        final run = await officialize(contestId);
        // The scores it made official are in the results already.
        if (run.changedScores) return null;
      } on Object catch (error, stackTrace) {
        _logger.warning(
          'Automatic officialization after $cause failed; it repeats on the '
          'next trigger',
          error,
          stackTrace,
        );
      }
    }
    return recalculateWithoutOfficialization(contestId, cause: cause);
  }

  /// As [recalculateAfterEntry] without accepting any score first, for a
  /// change that must leave pending scores pending: the first upload of a
  /// contest (an import's own replicated rows).
  Future<String?> recalculateWithoutOfficialization(
    Id contestId, {
    String cause = 'a score entry',
  }) async {
    try {
      await _results.recalculate(contestId);
      return null;
    } on ContestStateError catch (error, stackTrace) {
      final warning =
          'Recalculation was refused after $cause; the results are stale';
      _logger.warning(warning, error, stackTrace);
      return warning;
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Recalculation after $cause failed; retrying once',
        error,
        stackTrace,
      );
    }
    try {
      await _results.recalculate(contestId);
      return null;
    } on Object catch (error, stackTrace) {
      final warning =
          'Recalculation failed after $cause; the results are stale';
      _logger.warning(warning, error, stackTrace);
      return warning;
    }
  }
}
