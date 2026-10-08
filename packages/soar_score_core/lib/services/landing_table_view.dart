import 'package:equatable/equatable.dart';

import '../models/landing/landing_result.dart';
import '../models/landing/landing_table.dart';
import '../models/landing/landing_table_with_results.dart';

/// A landing table with its entries and whether anything refers to it.
///
/// A table that is in use is locked: it cannot be removed, and it never
/// changes anyway, because a change is a new table.
class LandingTableView extends Equatable {
  const LandingTableView({required this.content, required this.inUse});

  factory LandingTableView.fromJson(Map<String, Object?> json) =>
      LandingTableView(
        content: LandingTableWithResults(
          table: LandingTable.fromJson(json['table']! as Map<String, Object?>),
          results: [
            for (final item in json['results']! as List<Object?>)
              LandingResult.fromJson(item! as Map<String, Object?>),
          ],
        ),
        inUse: json['in_use']! as bool,
      );

  final LandingTableWithResults content;

  /// Whether a profile, preset or contest configuration refers to the table.
  final bool inUse;

  LandingTable get table => content.table;
  List<LandingResult> get results => content.results;

  Map<String, Object?> toJson() => {
    'table': table.toJson(),
    'results': [for (final result in results) result.toJson()],
    'in_use': inUse,
  };

  @override
  List<Object?> get props => [content, inUse];
}
