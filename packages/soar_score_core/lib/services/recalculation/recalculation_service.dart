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
/// A [ContestStateError] (the contest is not configured, or its discipline is
/// not calculated yet) is a refusal, not a transient failure: it is not
/// retried and it is rethrown so the handler can answer 409.
class RecalculationService {
  RecalculationService(this._results);

  final ResultsService _results;

  /// Recalculates the results of [contestId] after a score entry.
  ///
  /// Returns `null` when the recalculation succeeded (possibly after one
  /// retry), or a warning string naming the failure when it failed twice.
  /// The score that triggered it is already stored in both cases; the
  /// results read as stale until a later recalculation succeeds.
  Future<String?> recalculateAfterEntry(Id contestId) async {
    try {
      await _results.recalculate(contestId);
      return null;
    } on ContestStateError {
      // A refusal: not transient, not retried. The handler answers 409.
      rethrow;
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Recalculation after a score entry failed; retrying once',
        error,
        stackTrace,
      );
    }
    try {
      await _results.recalculate(contestId);
      return null;
    } on ContestStateError {
      rethrow;
    } on Object catch (error, stackTrace) {
      final warning =
          'Recalculation failed after a score entry; the results are stale';
      _logger.warning(warning, error, stackTrace);
      return warning;
    }
  }
}