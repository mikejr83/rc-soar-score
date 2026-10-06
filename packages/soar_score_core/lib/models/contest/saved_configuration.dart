import 'package:equatable/equatable.dart';

import 'contest.dart';
import 'contest_configuration_revision.dart';

/// A configuration revision and the contest it was stored with.
///
/// Saving a revision also touches the contest (its revision, update time
/// and possibly its lifecycle state), so both come back together. Stored as
/// one unit; not an entity itself.
class SavedConfiguration extends Equatable {
  const SavedConfiguration({required this.revision, required this.contest});

  factory SavedConfiguration.fromJson(Map<String, Object?> json) =>
      SavedConfiguration(
        revision: ContestConfigurationRevision.fromJson(
          json['configuration'] as Map<String, Object?>,
        ),
        contest: Contest.fromJson(json['contest'] as Map<String, Object?>),
      );

  final ContestConfigurationRevision revision;
  final Contest contest;

  Map<String, Object?> toJson() => {
    'configuration': revision.toJson(),
    'contest': contest.toJson(),
  };

  @override
  List<Object?> get props => [revision, contest];
}
