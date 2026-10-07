import 'package:soar_score_core/soar_score_core.dart';

/// A person selected for the new contest in the draft.
class DraftParticipant {
  const DraftParticipant({
    required this.profileId,
    required this.name,
    this.isPilot = true,
    this.classification = '',
    this.team = '',
  });

  final Id profileId;
  final String name;

  /// Whether the participant has the `Pilot` role (non-flying roles get no
  /// score rows).
  final bool isPilot;

  final String classification;

  /// The team name; empty means not assigned to a team.
  final String team;

  DraftParticipant copyWith({String? classification, String? team}) =>
      DraftParticipant(
        profileId: profileId,
        name: name,
        isPilot: isPilot,
        classification: classification ?? this.classification,
        team: team ?? this.team,
      );
}
