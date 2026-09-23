import '../models/contest.dart';
import '../models/id.dart';

/// Abstract persistence contract for [Contest] entities.
///
/// `soar_score_core` owns only the contract; the concrete
/// repositories live in the data-access packages (e.g.
/// `soar_score_data_sqlite`) so server-side and client-side stores
/// remain interchangeable.
abstract interface class ContestRepository {
  /// Loads a single contest by [id], or `null` when none exists.
  Future<Contest?> findById(Id id);

  /// Loads every persisted contest.
  Future<List<Contest>> getAll();

  /// Inserts [contest], or updates the existing row with the same id.
  Future<Contest> save(Contest contest);

  /// Deletes the contest with [id]; returns whether a row was removed.
  Future<bool> delete(Id id);

  /// Releases the underlying storage connection.
  Future<void> close();
}
