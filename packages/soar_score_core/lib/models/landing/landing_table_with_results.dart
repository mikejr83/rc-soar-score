import 'package:equatable/equatable.dart';

import 'landing_result.dart';
import 'landing_table.dart';

/// A [LandingTable] together with its [LandingResult]s, the unit in which a
/// table is created: both exist together and never change afterwards.
///
/// The results are held in selection order. Construction rejects a table with
/// no results, a result that belongs to another table, and a repeated entry
/// key or ordinal position.
class LandingTableWithResults extends Equatable {
  LandingTableWithResults({
    required this.table,
    required Iterable<LandingResult> results,
  }) : results = List.unmodifiable(
         [...results]..sort((a, b) => a.ordinalPosition - b.ordinalPosition),
       ) {
    if (this.results.isEmpty) {
      throw ArgumentError.value(results, 'results', 'must not be empty');
    }
    final keys = <String>{};
    final positions = <int>{};
    for (final result in this.results) {
      if (result.landingTableId != table.id) {
        throw ArgumentError.value(
          result.id.value,
          'results',
          'belongs to another landing table',
        );
      }
      if (!keys.add(result.entryKey)) {
        throw ArgumentError.value(
          result.entryKey,
          'results',
          'entry key is repeated',
        );
      }
      if (!positions.add(result.ordinalPosition)) {
        throw ArgumentError.value(
          result.ordinalPosition,
          'results',
          'ordinal position is repeated',
        );
      }
    }
  }

  final LandingTable table;

  /// The selectable entries, by ordinal position.
  final List<LandingResult> results;

  @override
  List<Object?> get props => [table, results];
}
