import '../models/id.dart';
import '../models/results/flight_result.dart';
import '../models/results/participation_standing.dart';
import '../models/results/team_standing.dart';

/// Abstract persistence contract for [FlightResult]s.
///
/// Results are derived data: the calculator recomputes them, so they have no
/// revision, mutation or tombstone, and are never replicated.
abstract interface class FlightResultRepository {
  Future<FlightResult?> findById(Id id);

  /// The result of [scorePlaceholderId], or `null`; a placeholder has at most
  /// one.
  Future<FlightResult?> findForPlaceholder(Id scorePlaceholderId);

  /// The results of [contestId], in the order they were created.
  Future<List<FlightResult>> listForContest(Id contestId);

  /// The results of [contestParticipationId], in the order they were created.
  Future<List<FlightResult>> listForParticipation(Id contestParticipationId);

  /// Replaces every result of [contestId] with [results], in one transaction.
  ///
  /// Throws an `ArgumentError` if a result belongs to another contest.
  Future<void> replaceForContest(Id contestId, Iterable<FlightResult> results);

  /// Replaces every flight result, participation standing and team standing of
  /// [contestId] in one transaction.
  ///
  /// Throws an [ArgumentError] if an entity belongs to another contest.
  Future<void> replaceResultsForContest({
    required Id contestId,
    Iterable<FlightResult> flights = const [],
    Iterable<ParticipationStanding> standings = const [],
    Iterable<TeamStanding> teamStandings = const [],
  });
}
