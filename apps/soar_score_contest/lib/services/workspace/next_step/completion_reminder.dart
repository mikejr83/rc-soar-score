/// How long without a new score before the workspace suggests completing the
/// contest.
///
/// A fixed platform value, not a contest option; see "Not options" in
/// `plan/data-model/contest-options.md`. The reminder is advisory: the
/// director decides.
const Duration completionReminderAfter = Duration(hours: 48);
