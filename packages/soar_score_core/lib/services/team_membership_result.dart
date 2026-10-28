import 'package:equatable/equatable.dart';

import '../models/teams/team_membership.dart';

/// The answer to putting a participant on a team: the stored membership, and
/// a notice when the recalculation that follows a team change failed, so the
/// results read as stale.
class TeamMembershipResult extends Equatable {
  const TeamMembershipResult({
    required this.membership,
    this.recalculationWarning,
  });

  /// The membership's own JSON with `recalculation_warning` beside it, so a
  /// caller that only reads the membership still can.
  factory TeamMembershipResult.fromJson(Map<String, Object?> json) =>
      TeamMembershipResult(
        membership: TeamMembership.fromJson(json),
        recalculationWarning: json['recalculation_warning'] as String?,
      );

  final TeamMembership membership;

  /// A human-readable notice that the recalculation failed, or null.
  final String? recalculationWarning;

  Map<String, Object?> toJson() => {
    ...membership.toJson(),
    'recalculation_warning': recalculationWarning,
  };

  @override
  List<Object?> get props => [membership, recalculationWarning];
}
