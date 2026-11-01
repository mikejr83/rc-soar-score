import 'package:soar_score_core/soar_score_core.dart';

import '../participants/model_entry.dart';
import '../participants/participant_row.dart';
import '../participants/participant_row_style.dart';

/// A person in a stored contest: the participation, the profile it reads its
/// name and email from, and the cells the director can edit here.
///
/// The editable cells (role, class, team) are the saved values until the
/// director edits them; [withEdits] returns the edited copy and
/// [changedFrom] says which cells differ from the saved row.
class StoredParticipant implements ParticipantRow {
  StoredParticipant({
    required this.participation,
    required this.profile,
    this.team = '',
    this.membershipId,
    this.models = const [],
    Id? roleId,
    String? roleName,
    bool? isPilot,
    String? classification,
  }) : roleId = roleId ?? participation.roleId,
       roleName = roleName ?? participation.roleName,
       isPilot = isPilot ?? participation.roleType == RoleType.pilot,
       classification = classification ?? participation.classification ?? '';

  /// The stored participation, with the revision a save is based on.
  final ContestParticipation participation;
  final ParticipantProfile profile;

  /// The team membership the saved [team] came from, if any.
  final Id? membershipId;

  @override
  final Id roleId;
  @override
  final String roleName;
  @override
  final bool isPilot;
  @override
  final String classification;
  @override
  final String team;

  /// The saved models of the pilot, which are edited and saved on their own.
  @override
  final List<ModelEntry> models;

  Id get id => participation.id;

  @override
  String get rowId => participation.id.value;

  @override
  String get name => '${profile.firstName} ${profile.lastName}';

  /// The participant number allocated at the draw, if any.
  int? get number => participation.participantNumber;

  /// The profile's email as a status: your own profiles are always visible.
  @override
  ParticipantEmailStatus get emailStatus {
    final email = profile.email;
    return email == null || email.isEmpty
        ? ParticipantEmailStatus.none
        : ParticipantEmailStatus.has;
  }

  /// The profile's email, for matching the search text. It is never shown.
  String? get email => profile.email;

  @override
  StoredParticipant withEdits({
    Role? role,
    String? classification,
    String? team,
    List<ModelEntry>? models,
  }) {
    final pilot = role == null ? isPilot : role.type == RoleType.pilot;
    return StoredParticipant(
      participation: participation,
      profile: profile,
      membershipId: membershipId,
      models: this.models,
      roleId: role?.id ?? roleId,
      roleName: role?.displayName ?? roleName,
      isPilot: pilot,
      // A non-flying role has no class.
      classification: pilot ? classification ?? this.classification : '',
      team: team ?? this.team,
    );
  }

  /// This row with its saved [models] replaced, keeping the unsaved edits.
  StoredParticipant withModels(List<ModelEntry> models) => StoredParticipant(
    participation: participation,
    profile: profile,
    membershipId: membershipId,
    models: models,
    roleId: roleId,
    roleName: roleName,
    isPilot: isPilot,
    classification: classification,
    team: team,
  );

  /// The cells that differ from [saved].
  Set<ParticipantCell> changedFrom(StoredParticipant saved) => {
    if (roleId != saved.roleId) ParticipantCell.role,
    if (classification.trim() != saved.classification.trim())
      ParticipantCell.classification,
    if (team.trim() != saved.team.trim()) ParticipantCell.team,
  };
}
