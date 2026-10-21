import 'package:equatable/equatable.dart';

import 'contest.dart';
import 'contest_configuration_revision.dart';

/// A configuration revision and the contest it was stored with.
///
/// Saving a revision also touches the contest (its revision, update time
/// and possibly its lifecycle state), so both come back together. Stored as
/// one unit; not an entity itself.
class SavedConfiguration extends Equatable {
  const SavedConfiguration({
    required this.revision,
    required this.contest,
    this.recalculationWarning,
  });

  factory SavedConfiguration.fromJson(Map<String, Object?> json) =>
      SavedConfiguration(
        revision: ContestConfigurationRevision.fromJson(
          json['configuration'] as Map<String, Object?>,
        ),
        contest: Contest.fromJson(json['contest'] as Map<String, Object?>),
        recalculationWarning: json['recalculation_warning'] as String?,
      );

  final ContestConfigurationRevision revision;
  final Contest contest;

  /// A notice that the recalculation that follows a saved revision failed or
  /// was refused, so the results read as stale until it succeeds; `null` when
  /// it succeeded or there was nothing to recalculate.
  final String? recalculationWarning;

  Map<String, Object?> toJson() => {
    'configuration': revision.toJson(),
    'contest': contest.toJson(),
    if (recalculationWarning != null)
      'recalculation_warning': recalculationWarning,
  };

  @override
  List<Object?> get props => [revision, contest, recalculationWarning];
}
