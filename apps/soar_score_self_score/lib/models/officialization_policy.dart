/// When the contest makes submitted scores official, as far as a pilot needs
/// to know. Mirrors the contest's `scores_become_official` option.
enum OfficializationPolicy {
  /// Once every score of the round has been submitted.
  endOfRound,

  /// Once every score of the pilot's group has been submitted.
  endOfGroup,

  /// Only when the director makes the score official.
  manual;

  /// Reads the option's wire value; null for a server that does not say or a
  /// value this app does not know, so the page falls back to general wording.
  static OfficializationPolicy? fromWire(String? value) => switch (value) {
    'EndOfRound' => endOfRound,
    'EndOfGroup' => endOfGroup,
    'Manual' => manual,
    _ => null,
  };
}
