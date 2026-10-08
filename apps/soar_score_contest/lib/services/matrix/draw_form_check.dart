/// The result of checking the draw form's two numbers against the pilots who
/// will be drawn (`plan/ui/contest-administration/matrix-design-brief.md`).
class DrawFormCheck {
  const DrawFormCheck._({
    required this.rounds,
    required this.groups,
    this.roundsError,
    this.groupsError,
    this.groupsWarning,
    this.sizes = const [],
  });

  /// Checks [roundsText] and [groupsText] for [pilots] scoring pilots.
  ///
  /// [minimumGroups] is the team-protection minimum (the largest team's
  /// size), or 0 when team protection is off. An empty field is only an
  /// error once [submitted], so the form does not scold before it is used.
  factory DrawFormCheck.evaluate({
    required String roundsText,
    required String groupsText,
    required int pilots,
    required int minimumGroups,
    required bool submitted,
  }) {
    final rounds = _whole(roundsText);
    final groups = _whole(groupsText);
    String? roundsError;
    String? groupsError;
    if (roundsText.trim().isEmpty) {
      if (submitted) {
        roundsError = 'Enter the number of rounds.';
      }
    } else if (rounds == null || rounds < 1) {
      roundsError = 'Enter a whole number above 0.';
    }
    if (groupsText.trim().isEmpty) {
      if (submitted) {
        groupsError = 'Enter the number of groups per round.';
      }
    } else if (groups == null || groups < 1) {
      groupsError = 'Enter a whole number above 0.';
    } else if (minimumGroups > 0 && groups < minimumGroups) {
      groupsError =
          'At least $minimumGroups groups are needed with team protection on.';
    } else if (groups > pilots) {
      groupsError = 'There are only $pilots scoring pilots.';
    }
    final sizes = groups != null && groups >= 1 && groups <= pilots
        ? splitGroups(pilots, groups)
        : const <int>[];
    final small = [
      for (var i = 0; i < sizes.length; i++)
        if (sizes[i] < 2) i,
    ];
    String? warning;
    if (small.isNotEmpty) {
      final subject = small.length == 1
          ? 'Group ${groupLetter(small.first)} would have'
          : '${small.length} groups would have';
      warning =
          '$subject 1 pilot. A group needs at least 2 pilots to fly against '
          'each other.';
    }
    return DrawFormCheck._(
      rounds: rounds,
      groups: groups,
      roundsError: roundsError,
      groupsError: groupsError,
      groupsWarning: warning,
      sizes: sizes,
    );
  }

  /// A whole number from [text], or `null`.
  static int? _whole(String text) {
    final trimmed = text.trim();
    return RegExp(r'^\d+$').hasMatch(trimmed) ? int.parse(trimmed) : null;
  }

  /// [pilots] split into [groups] groups that differ by at most one pilot,
  /// larger groups first.
  static List<int> splitGroups(int pilots, int groups) => [
    for (var i = 0; i < groups; i++)
      pilots ~/ groups + (i < pilots % groups ? 1 : 0),
  ];

  /// "A", "B", … for a zero-based group index; "27" and up are numbers.
  static String groupLetter(int index) =>
      index < 26 ? String.fromCharCode(65 + index) : '${index + 1}';

  /// The typed numbers when they are whole numbers.
  final int? rounds;
  final int? groups;

  final String? roundsError;
  final String? groupsError;

  /// Set when a group would have fewer than two pilots. It never blocks.
  final String? groupsWarning;

  /// The resulting group sizes; empty until the groups number fits.
  final List<int> sizes;

  /// Whether the draw can be asked for.
  bool get valid =>
      rounds != null &&
      groups != null &&
      roundsError == null &&
      groupsError == null;
}
