import '../models/id.dart';
import '../models/results/flight_result.dart';
import '../models/results/participation_standing.dart';
import '../models/results/team_standing.dart';

/// Abstract persistence contract for the derived results of a contest:
/// flight results, participation standings and team standings.
///
/// The results are recomputed by the calculator, so they have no revision,
/// mutation or tombstone, and are never replicated.
abstract interface class ResultsRepository {
  /// Replaces the flight results, participation standings and team
  /// standings of [contestId] with the given rows, in one transaction.
  ///
  /// Throws an `ArgumentError` if a row belongs to another contest.
  Future<void> replaceResultsForContest(
    Id contestId,
    Iterable<FlightResult> flights,
    Iterable<ParticipationStanding> standings,
    Iterable<TeamStanding> teams,
  );
}
