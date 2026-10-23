import '../models/landing_result.dart';

/// Landing tables with more results than this use the autocomplete control;
/// smaller ones use the bottom sheet. See
/// `plan/ui/participant-scoring/landing-control-decision.md`.
const landingSheetMaxResults = 20;

bool landingUsesSheet(List<LandingResult> table) =>
    table.length <= landingSheetMaxResults;

/// Results whose label contains [query]. A numeric label such as `12"` is
/// found by typing its number. An empty query matches everything.
List<LandingResult> searchLandingTable(
  List<LandingResult> table,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return table;
  return [
    for (final result in table)
      if (result.label.toLowerCase().contains(q)) result,
  ];
}
