import 'package:soar_score_core/soar_score_core.dart';

/// A team's marker in the grid: a two-letter code plus a palette slot. The
/// code carries the identity; the colour only helps.
class TeamMarker {
  const TeamMarker({
    required this.name,
    required this.code,
    required this.paletteIndex,
  });

  final String name;
  final String code;

  /// Position in the team order, from 0. The palette repeats every
  /// [paletteSize] teams.
  final int paletteIndex;

  static const int paletteSize = 12;

  /// Teams 13 and up are drawn outlined, so they differ from teams 1 to 12
  /// that share their colour.
  bool get outlined => paletteIndex >= paletteSize;
}

/// The markers of a contest's teams, assigned in team-name order so they stay
/// the same between visits.
class TeamMarkers {
  TeamMarkers._(this._byTeam, this.ordered);

  factory TeamMarkers.of(Iterable<Team> teams) {
    final sorted = teams.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final used = <String>{};
    final byTeam = <Id, TeamMarker>{};
    final ordered = <(Id, TeamMarker)>[];
    for (var i = 0; i < sorted.length; i++) {
      final team = sorted[i];
      final marker = TeamMarker(
        name: team.name,
        code: _uniqueCode(team.name, used),
        paletteIndex: i,
      );
      byTeam[team.id] = marker;
      ordered.add((team.id, marker));
    }
    return TeamMarkers._(byTeam, ordered);
  }

  final Map<Id, TeamMarker> _byTeam;

  /// The teams with their markers, in marker order.
  final List<(Id, TeamMarker)> ordered;

  TeamMarker? of(Id? teamId) => teamId == null ? null : _byTeam[teamId];

  static String _uniqueCode(String name, Set<String> used) {
    final words = name
        .split(RegExp(r'[^A-Za-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final letters = words.join();
    final candidates = <String>[
      if (words.length >= 2) '${words[0][0]}${words[1][0]}',
      if (letters.length >= 2) letters.substring(0, 2),
      if (words.length >= 2)
        for (var i = 1; i < words[1].length; i++)
          '${words[0][0]}${words[1][i]}',
      for (var i = 1; i < letters.length; i++) '${letters[0]}${letters[i]}',
    ].map((code) => code.toUpperCase());
    for (final code in candidates) {
      if (used.add(code)) {
        return code;
      }
    }
    for (var n = 1; ; n++) {
      final code = '${letters.isEmpty ? 'T' : letters[0].toUpperCase()}$n';
      if (used.add(code)) {
        return code;
      }
    }
  }
}
