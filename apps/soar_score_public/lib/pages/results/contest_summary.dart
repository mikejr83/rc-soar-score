import 'package:soar_score_api/soar_score_api.dart';

/// Whether a listed contest is still being flown or is finished.
enum ContestStatus { inProgress, completed }

/// One row of the contest search list, parsed once from the untyped
/// `contest` identity map of a Public publication summary.
class ContestSummary {
  const ContestSummary({
    required this.publicationId,
    required this.name,
    required this.start,
    required this.end,
    required this.venue,
    required this.status,
  });

  factory ContestSummary.fromDto(
    PublicPublicationSummaryDto dto, {
    required DateTime now,
  }) {
    final contest = dto.contest;
    String? text(String key) {
      final value = contest[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    DateTime? date(String key) {
      final value = text(key);
      return value == null ? null : DateTime.tryParse(value)?.toLocal();
    }

    final start = date('start') ?? dto.publishedAt.toLocal();
    final end = date('end') ?? start;
    return ContestSummary(
      publicationId: dto.publicationId.value,
      name: text('name') ?? 'Untitled contest',
      start: start,
      end: end,
      venue: [
        for (final key in const ['host', 'city', 'state', 'country'])
          ?text(key),
      ].join(', '),
      status: _status(text('status'), end, now),
    );
  }

  final String publicationId;
  final String name;
  final DateTime start;
  final DateTime end;

  /// Host, city, state and country, whichever are set; empty when none are.
  final String venue;
  final ContestStatus status;

  /// The projection does not carry a contest status yet (#454). Until it
  /// does, a recognised `status` value wins and otherwise the contest is
  /// completed once its end date has passed. The identity's `state` key is
  /// the venue's state or province, not a status, so it is not read here.
  static ContestStatus _status(String? raw, DateTime end, DateTime now) {
    switch (raw?.toLowerCase()) {
      case 'completed':
        return ContestStatus.completed;
      case 'in_progress':
      case 'running':
        return ContestStatus.inProgress;
    }
    return end.isBefore(now)
        ? ContestStatus.completed
        : ContestStatus.inProgress;
  }

  /// Local calendar day of the start, for date-only comparisons.
  DateTime get startDay => DateTime(start.year, start.month, start.day);

  /// True when the contest starts after the coming Sunday: a future contest
  /// is listed only through the following weekend. Client-side until #455
  /// moves the rule to the server.
  bool startsAfterComingSunday(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final sunday = today.add(
      Duration(days: (DateTime.sunday - now.weekday) % 7),
    );
    return startDay.isAfter(sunday);
  }

  /// True when the contest was flown, in whole or in part, in the 30 days
  /// before [now]. Client-side until #455.
  bool activeInLast30Days(DateTime now) =>
      !start.isAfter(now) &&
      end.isAfter(now.subtract(const Duration(days: 30)));
}
