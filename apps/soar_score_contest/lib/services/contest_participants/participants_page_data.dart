import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/matrix_page_data.dart';
import '../participants/model_entry.dart';
import '../participants/participant_option.dart';
import 'stored_participant.dart';

/// Everything the Participants page shows about one contest, as loaded.
class ParticipantsPageData {
  ParticipantsPageData({
    required this.base,
    required this.roles,
    required Set<Id> participationsWithScores,
    this.modelLinks = const [],
  }) : _withScores = participationsWithScores;

  /// Loads the contest, its people, teams, matrix, scores and the roles.
  static Future<ParticipantsPageData> load(ApiClient client, Id id) async {
    final results = await Future.wait<Object?>([
      MatrixPageData.load(client, id),
      client.scores(id),
      client.roles(),
      client.modelLinks(id),
    ]);
    final scores = results[1]! as ContestScores;
    return ParticipantsPageData(
      base: results[0]! as MatrixPageData,
      roles: _usable(results[2]! as List<Role>),
      modelLinks: results[3]! as List<ContestModelLink>,
      participationsWithScores: {
        for (final slot in scores.slots)
          if (slot.placeholder.state != ScorePlaceholderState.notEntered)
            slot.placeholder.contestParticipationId,
      },
    );
  }

  /// The roles a director can pick: not archived, Pilot first.
  static List<Role> _usable(List<Role> roles) =>
      roles.where((role) => role.archivedAt == null).toList()..sort((a, b) {
        if (a.type == b.type) {
          return a.displayName.compareTo(b.displayName);
        }
        return a.type == RoleType.pilot ? -1 : 1;
      });

  final MatrixPageData base;
  final List<Role> roles;
  final Set<Id> _withScores;

  /// The models of every pilot of the contest.
  final List<ContestModelLink> modelLinks;

  Contest get contest => base.contest;

  /// Whether a matrix has been drawn.
  bool get drawn => !base.matrix.isEmpty;

  /// Whether any pilot has a score in any round.
  bool get hasScores => _withScores.isNotEmpty;

  /// Whether the pilot of [participation] has a score in any round.
  bool hasFlights(Id participation) => _withScores.contains(participation);

  /// Whether the matrix has a place for the pilot of [participation].
  bool hasMatrixRows(Id participation) => base.matrix.assignments.any(
    (assignment) => assignment.contestParticipationId == participation,
  );

  /// The options turned on for the contest. Without a saved configuration
  /// nothing optional is on.
  Set<ParticipantOption> get options {
    final core = base.options;
    return {
      if (core?.teamsEnabled ?? false) ParticipantOption.teams,
      if (core?.participantNumbersEnabled ?? false)
        ParticipantOption.pilotNumbers,
      if (core?.classesEnabled ?? false) ParticipantOption.classes,
      if (core?.rolesEnabled ?? false) ParticipantOption.roles,
      if (core?.modelsEnabled ?? false) ParticipantOption.models,
    };
  }

  /// The people of the contest in the order they were added.
  List<StoredParticipant> get participants {
    final profiles = {for (final p in base.profiles) p.id: p};
    final teams = {for (final t in base.teams) t.id: t};
    final memberships = {
      for (final m in base.memberships) m.contestParticipationId: m,
    };
    return [
      for (final participation in base.participations)
        if (profiles[participation.participantProfileId] case final profile?)
          StoredParticipant(
            participation: participation,
            profile: profile,
            team: teams[memberships[participation.id]?.teamId]?.name ?? '',
            membershipId: memberships[participation.id]?.id,
            models: [
              for (final link in modelLinks)
                if (link.contestParticipationId == participation.id)
                  ModelEntry.fromLink(link),
            ],
          ),
    ];
  }
}
