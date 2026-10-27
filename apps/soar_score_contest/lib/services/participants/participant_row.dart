import 'package:soar_score_core/soar_score_core.dart';

import 'participant_option.dart';

/// Where a selected participant's profile came from.
enum ParticipantSource {
  /// One of the director's own participant profiles. Its email was entered
  /// by the director, so it is always shown.
  local,

  /// A profile found through the remote participant directory. Its email is
  /// shown only when the person allows it.
  remote,
}

/// What a row's email cell says. The address itself is never shown.
enum ParticipantEmailStatus {
  has('Has email', 'Email on the profile'),
  none('None', 'No email on the profile'),
  private('Private', 'This person hasn’t allowed their email to be shown.');

  const ParticipantEmailStatus(this.label, this.explanation);

  final String label;
  final String explanation;
}

/// What a participant row still needs before the contest can go on.
enum ParticipantIssue {
  classification('class', 'enter a class');

  const ParticipantIssue(this.label, this.fix);

  /// Short name for the row status (`Needs class`).
  final String label;

  /// What to do, for the validation summary (`enter a class`).
  final String fix;
}

/// A team in use, with how many participants are on it.
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

/// One person in a participant list, as the shared table, cards and cells
/// see them: a wizard draft row or a stored participation.
abstract interface class ParticipantRow {
  /// The key for selection and focus (the profile id).
  String get rowId;

  String get name;

  ParticipantEmailStatus get emailStatus;

  Id get roleId;
  String get roleName;

  /// Whether the participant has the `Pilot` role (non-flying roles get no
  /// score rows).
  bool get isPilot;

  String get classification;

  /// The team name; empty means not assigned to a team.
  String get team;

  /// A copy with the given cells changed.
  ParticipantRow withEdits({Role? role, String? classification, String? team});
}

/// The rules the shared participant list applies to its rows. The wizard
/// answers them from the draft, the Participants page from stored data.
abstract interface class ParticipantListRules {
  /// Whether the contest has [option] turned on.
  bool has(ParticipantOption option);

  /// Whether [row] flies and is scored.
  bool isScoring(ParticipantRow row);

  /// What [row] still needs.
  List<ParticipantIssue> issuesOf(ParticipantRow row);

  /// The classes in use, in title case, for suggestions.
  List<String> get classes;

  /// The teams in use.
  List<TeamSummary> get teams;

  /// [typed] as a team name: an existing team that matches ignoring case
  /// keeps its spelling; a new name is title-cased; blank means no team.
  String normalizeTeam(String typed);

  /// The pilot number cell text for [row] (`3 · provisional`, `—`).
  String numberLabel(ParticipantRow row);
}
