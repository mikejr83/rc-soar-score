import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// A contest's days as the contests page and the "Is this you?" card show
/// them: one date, or a range. [start] and [end] are the contest's calendar
/// days in its own time zone (UTC midnight of that day).
String formatContestDates(
  AppLocalizations l10n,
  String locale,
  DateTime start,
  DateTime end,
) {
  final format = DateFormat.yMMMEd(locale);
  return start == end
      ? format.format(start)
      : l10n.contestDatesRange(format.format(start), format.format(end));
}
