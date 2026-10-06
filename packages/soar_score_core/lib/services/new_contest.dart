import '../models/id.dart';
import 'contest_details.dart';

/// What a director supplies to create a contest.
///
/// The caller generates [id], so a retried request finds the contest it
/// already created instead of creating a second one.
class NewContest {
  const NewContest({
    required this.id,
    required this.details,
    required this.timezone,
  });

  final Id id;
  final ContestDetails details;

  /// IANA timezone name, stored at creation.
  final String timezone;
}
