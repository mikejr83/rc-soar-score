import 'contest_draft.dart';
import 'draft_participant.dart';
import 'participant_option.dart';

/// What a participant row still needs before the wizard can continue.
enum ParticipantIssue {
  classification('class', 'enter a class'),
  model('model', 'add model details');

  const ParticipantIssue(this.label, this.fix);

  /// Short name for the row status (`Needs class`).
  final String label;

  /// What to do, for the validation summary (`enter a class`).
  final String fix;
}

/// A team named in the draft, with how many participants are on it.
class TeamSummary {
  const TeamSummary(this.name, this.count);

  final String name;
  final int count;
}

/// `open class` → `Open Class`.
String titleCase(String text) =>
    text.trim().replaceAllMapped(RegExp(r'\S+'), (match) {
      final word = match[0]!;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });

/// Up to two initials for an avatar: `Flying Gators` → `FG`.
String initials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .map((word) => word[0])
    .take(2)
    .join()
    .toUpperCase();

/// The step 4 rules over a draft's participants.
extension ParticipantRules on ContestDraft {
  /// Whether [participant] flies and is scored. Without contest roles
  /// everyone is a pilot.
  bool isScoring(DraftParticipant participant) =>
      !has(ParticipantOption.roles) || participant.isPilot;

  int get scoringCount => participants.where(isScoring).length;

  /// What [participant] still needs. Teams are optional (no name means
  /// unassigned); class and model details are required for scoring pilots
  /// when those options are on.
  List<ParticipantIssue> issuesOf(DraftParticipant participant) {
    if (!isScoring(participant)) {
      return const [];
    }
    return [
      if (has(ParticipantOption.classes) &&
          participant.classification.trim().isEmpty)
        ParticipantIssue.classification,
      if (has(ParticipantOption.models) &&
          (participant.model.trim().isEmpty ||
              participant.modelId.trim().isEmpty))
        ParticipantIssue.model,
    ];
  }

  List<DraftParticipant> get participantsNeedingFixes =>
      participants.where((p) => issuesOf(p).isNotEmpty).toList();

  /// The teams in use, matched ignoring case, in first-seen order.
  List<TeamSummary> get teams {
    final names = <String, String>{};
    final counts = <String, int>{};
    for (final participant in participants) {
      final name = participant.team.trim();
      if (name.isEmpty) {
        continue;
      }
      final key = name.toLowerCase();
      names.putIfAbsent(key, () => name);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return [
      for (final MapEntry(:key, :value) in names.entries)
        TeamSummary(value, counts[key]!),
    ];
  }

  /// The classes entered so far, in title case, for suggestions.
  List<String> get classes => {
    for (final participant in participants)
      if (participant.classification.trim().isNotEmpty)
        titleCase(participant.classification),
  }.toList();

  /// [typed] as a team name: an existing team that matches ignoring case
  /// keeps its spelling; a new name is title-cased; blank means no team.
  String normalizeTeam(String typed) {
    final name = typed.trim();
    if (name.isEmpty) {
      return '';
    }
    for (final team in teams) {
      if (team.name.toLowerCase() == name.toLowerCase()) {
        return team.name;
      }
    }
    return titleCase(name);
  }
}
