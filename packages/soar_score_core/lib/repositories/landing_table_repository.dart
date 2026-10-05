import '../models/id.dart';
import '../models/landing/landing_table_with_results.dart';

/// Abstract persistence contract for landing tables and their entries.
///
/// Tables are immutable, so there is no update or delete: a change is a new
/// table.
abstract interface class LandingTableRepository {
  /// The table with [id] and its entries, or `null` when it is not stored.
  Future<LandingTableWithResults?> findById(Id id);

  /// The system tables and the tables owned by [ownerAccountId], by name.
  ///
  /// With no [ownerAccountId], only the system tables.
  Future<List<LandingTableWithResults>> listVisibleTo({Id? ownerAccountId});

  /// Stores a system [table] and its entries in one transaction, so a table
  /// is complete or absent.
  ///
  /// Idempotent: returns `false` and changes nothing when a table with the
  /// same id is already stored, `true` when it was added. System data is
  /// seeded, so no mutation is recorded. Throws an `ArgumentError` when
  /// [table] has an owner.
  Future<bool> installSystemTable(LandingTableWithResults table);
}
