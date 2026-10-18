import 'contest_summary.dart';

/// The user-supplied contest search filters, carried as query parameters on
/// `/results/contests` so a filtered list can be bookmarked.
class ContestFilters {
  const ContestFilters({this.name = '', this.venue = '', this.from, this.to});

  factory ContestFilters.fromQuery(Map<String, String> query) => ContestFilters(
    name: query['name'] ?? '',
    venue: query['venue'] ?? '',
    from: _parseDay(query['from']),
    to: _parseDay(query['to']),
  );

  final String name;
  final String venue;

  /// Inclusive start-date bounds, as local calendar days.
  final DateTime? from;
  final DateTime? to;

  bool get isEmpty =>
      name.isEmpty && venue.isEmpty && from == null && to == null;

  /// Query parameters, with unset filters left out so the URL stays clean.
  Map<String, String> toQuery() => {
    if (name.isNotEmpty) 'name': name,
    if (venue.isNotEmpty) 'venue': venue,
    if (from != null) 'from': formatDay(from!),
    if (to != null) 'to': formatDay(to!),
  };

  /// [from] and [to] are passed as thunks so a filter can be cleared.
  ContestFilters copyWith({
    String? name,
    String? venue,
    DateTime? Function()? from,
    DateTime? Function()? to,
  }) => ContestFilters(
    name: name ?? this.name,
    venue: venue ?? this.venue,
    from: from == null ? this.from : from(),
    to: to == null ? this.to : to(),
  );

  bool matches(ContestSummary contest) {
    final day = contest.startDay;
    return _contains(contest.name, name) &&
        _contains(contest.venue, venue) &&
        (from == null || !day.isBefore(from!)) &&
        (to == null || !day.isAfter(to!));
  }

  static bool _contains(String haystack, String needle) =>
      needle.isEmpty || haystack.toLowerCase().contains(needle.toLowerCase());

  static DateTime? _parseDay(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// `yyyy-MM-dd` of a local day.
  static String formatDay(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
