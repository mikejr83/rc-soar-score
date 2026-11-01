import 'package:soar_score_core/soar_score_core.dart';

import '../participants/model_entry.dart';
import '../participants/participant_row.dart';

/// A person selected for the new contest in the draft.
class DraftParticipant implements ParticipantRow {
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
    this.models = const [],
  }) : roleId = roleId ?? SystemRoles.pilotId;

  final Id profileId;
  @override
  final String name;

  /// The email address, if the profile has one.
  final String? email;

  /// Whether [email] may be shown (always for local profiles).
  final bool emailVisible;

  final ParticipantSource source;

  @override
  final Id roleId;
  @override
  final String roleName;

  /// Whether the participant has the `Pilot` role (non-flying roles get no
  /// score rows).
  @override
  final bool isPilot;

  @override
  final String classification;

  /// The team name; empty means not assigned to a team.
  @override
  final String team;

  /// The models entered for the contest; a pilot may have none.
  @override
  final List<ModelEntry> models;

  @override
  String get rowId => profileId.value;

  @override
  ParticipantEmailStatus get emailStatus {
    if (source == ParticipantSource.remote && !emailVisible) {
      return ParticipantEmailStatus.private;
    }
    final address = email;
    return address == null || address.isEmpty
        ? ParticipantEmailStatus.none
        : ParticipantEmailStatus.has;
  }

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
    List<ModelEntry>? models,
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
    // A non-flying role has no models.
    models: role != null && role.type != RoleType.pilot
        ? const []
        : models ?? this.models,
  );

  @override
  DraftParticipant withEdits({
    Role? role,
    String? classification,
    String? team,
    List<ModelEntry>? models,
  }) => copyWith(
    role: role,
    classification: classification,
    team: team,
    models: models,
  );
}
