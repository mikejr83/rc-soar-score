import 'package:soar_score_core/soar_score_core.dart';

import '../new_contest/date_range_text.dart';

/// The line under a report's title that names where and when the contest is:
/// "Lake Wales, FL · 17–18 Oct 2026". The place is left out when the contest
/// has none.
String contestPlaceAndDates(Contest contest) {
  final place = [
    if (contest.city case final city? when city.trim().isNotEmpty) city,
    if (contest.state case final state? when state.trim().isNotEmpty) state,
  ].join(', ');
  final start = ContestTime.inZone(contest.startDateTime, contest.timezone);
  final end = ContestTime.inZone(contest.endDateTime, contest.timezone);
  return [if (place.isNotEmpty) place, dateRangeText(start, end)].join(' · ');
}
