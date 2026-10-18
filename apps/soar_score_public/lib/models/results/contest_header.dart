/// The contest identity the page header shows, parsed once from the
/// projection's `contest` map.
class ContestHeader {
  const ContestHeader({
    required this.name,
    required this.start,
    required this.end,
    required this.venue,
    required this.discipline,
    required this.isCompleted,
  });

  factory ContestHeader.fromJson(
    Map<String, Object?> contest, {
    DateTime Function() now = DateTime.now,
  }) {
    final end = DateTime.tryParse(contest['end'] as String? ?? '');
    return ContestHeader(
      name: contest['name'] as String? ?? 'Untitled contest',
      start: DateTime.tryParse(contest['start'] as String? ?? ''),
      end: end,
      venue: [
        for (final key in const ['host', 'city', 'state', 'country'])
          if (contest[key] case final String value when value.isNotEmpty) value,
      ].join(', '),
      discipline: contest['discipline'] as String? ?? '',
      isCompleted: _isCompleted(contest['status'], end, now()),
    );
  }

  final String name;
  final DateTime? start;
  final DateTime? end;
  final String venue;
  final String discipline;
  final bool isCompleted;

  String get status => isCompleted ? 'Completed' : 'In progress';

  /// Completed comes from the contest lifecycle state. The projection does
  /// not carry it yet (#454; `state` is taken by the venue, so it is read as
  /// `status` here), so until that key arrives a contest whose end date has
  /// passed counts as completed.
  static bool _isCompleted(Object? status, DateTime? end, DateTime now) {
    if (status is String) return status == 'Completed';
    return end != null && end.isBefore(now);
  }
}
