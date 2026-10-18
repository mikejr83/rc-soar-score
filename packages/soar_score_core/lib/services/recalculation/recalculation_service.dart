import 'package:logging/logging.dart';

import '../../errors/contest_state_error.dart';
import '../../models/id.dart';
import '../results_service.dart';

final _logger = Logger('RecalculationService');

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
class RecalculationService {
  RecalculationService(this._results);

  final ResultsService _results;

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
