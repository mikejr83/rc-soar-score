import 'participant_row.dart';

/// The teams named in [names], matched ignoring case, in first-seen order,
/// with how many people are on each. Blank names are unassigned.
List<TeamSummary> summarizeTeams(Iterable<String> names) {
  final spelling = <String, String>{};
  final counts = <String, int>{};
  for (final raw in names) {
    final name = raw.trim();
    if (name.isEmpty) {
      continue;
    }
    final key = name.toLowerCase();
    spelling.putIfAbsent(key, () => name);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return [
    for (final MapEntry(:key, :value) in spelling.entries)
      TeamSummary(value, counts[key]!),
  ];
}

/// The distinct classes in [values], in title case, for suggestions.
List<String> distinctClasses(Iterable<String> values) => {
  for (final value in values)
    if (value.trim().isNotEmpty) titleCase(value),
}.toList();

/// [typed] as a team name: an existing team that matches ignoring case keeps
/// its spelling; a new name is title-cased; blank means no team.
String normalizeTeamName(String typed, List<TeamSummary> teams) {
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
