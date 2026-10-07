import 'package:soar_score_core/soar_score_core.dart';

/// Where a selected participant's profile came from.
enum ParticipantSource {
  /// One of the director's own participant profiles. Its email was entered
  /// by the director, so it is always shown.
  local,

  /// A profile found through the remote participant directory. Its email is
  /// shown only when the person allows it.
  remote,
}

/// A person selected for the new contest in the draft.
class DraftParticipant {
  DraftParticipant({
    required this.profileId,
    required this.name,
    this.email,
    this.emailVisible = true,
    this.source = ParticipantSource.local,
    Id? roleId,
    this.roleName = 'Pilot',
    this.isPilot = true,
    this.classification = '',
    this.team = '',
    this.model = '',
    this.modelId = '',
  }) : roleId = roleId ?? SystemRoles.pilotId;

  final Id profileId;
  final String name;

  /// The email address, if the profile has one.
  final String? email;

  /// Whether [email] may be shown (always for local profiles).
  final bool emailVisible;

  final ParticipantSource source;

  final Id roleId;
  final String roleName;

  /// Whether the participant has the `Pilot` role (non-flying roles get no
  /// score rows).
  final bool isPilot;

  final String classification;

  /// The team name; empty means not assigned to a team.
  final String team;

  /// The model name and ID (kept in the draft only; participations have no
  /// place for them yet).
  final String model;
  final String modelId;

  /// A participant for one of the director's own [profile]s, as a Pilot.
  factory DraftParticipant.fromProfile(ParticipantProfile profile) =>
      DraftParticipant(
        profileId: profile.id,
        name: '${profile.firstName} ${profile.lastName}',
        email: profile.email,
      );

  DraftParticipant copyWith({
    Role? role,
    String? classification,
    String? team,
    String? model,
    String? modelId,
  }) => DraftParticipant(
    profileId: profileId,
    name: name,
    email: email,
    emailVisible: emailVisible,
    source: source,
    roleId: role?.id ?? roleId,
    roleName: role?.displayName ?? roleName,
    isPilot: role == null ? isPilot : role.type == RoleType.pilot,
    classification: classification ?? this.classification,
    team: team ?? this.team,
    model: model ?? this.model,
    modelId: modelId ?? this.modelId,
  );
}
