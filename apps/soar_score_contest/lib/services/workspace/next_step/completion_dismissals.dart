import 'completion_reminder.dart';

/// The completion suggestions the director has dismissed, per contest.
///
/// In memory only: a reload of the app brings the suggestion back. Persisting
/// the dismissal is #319.
class CompletionDismissals {
  final Map<String, _Dismissal> _byContest = {};

  /// Records that the suggestion for [contestId] was dismissed at [now] while
  /// the latest score was [latestScoreAt] (`null` when there is none).
  void dismiss(String contestId, {DateTime? latestScoreAt, DateTime? now}) {
    _byContest[contestId] = _Dismissal(
      latestScoreAt: latestScoreAt,
      dismissedAt: now ?? DateTime.now().toUtc(),
    );
  }

  /// True while the dismissal for [contestId] still holds: no newer score has
  /// arrived since and [completionReminderAfter] has not passed again.
  bool isDismissed(
    String contestId, {
    required DateTime? latestScoreAt,
    required DateTime now,
  }) {
    final dismissal = _byContest[contestId];
    if (dismissal == null) {
      return false;
    }
    if (dismissal.latestScoreAt != latestScoreAt) {
      return false;
    }
    return now.difference(dismissal.dismissedAt) < completionReminderAfter;
  }
}

class _Dismissal {
  const _Dismissal({required this.latestScoreAt, required this.dismissedAt});

  final DateTime? latestScoreAt;
  final DateTime dismissedAt;
}
