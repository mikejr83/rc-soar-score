import '../participants/participant_lists.dart';
import '../participants/participant_option.dart';
import '../participants/participant_row.dart';
import 'stored_participant.dart';

/// The participant list rules answered from the rows of a stored contest.
class StoredListRules implements ParticipantListRules {
  StoredListRules({
    required this.options,
    required this.rows,
    required this.drawn,
  });

  final Set<ParticipantOption> options;

  /// The rows with the director's edits applied.
  final List<StoredParticipant> rows;

  /// Whether a matrix has been drawn (pilot numbers are allocated).
  final bool drawn;

  @override
  bool has(ParticipantOption option) => options.contains(option);

  @override
  bool isScoring(ParticipantRow row) =>
      !has(ParticipantOption.roles) || row.isPilot;

  /// A scoring pilot needs a class when classes are on.
  @override
  List<ParticipantIssue> issuesOf(ParticipantRow row) => [
    if (isScoring(row) &&
        has(ParticipantOption.classes) &&
        row.classification.trim().isEmpty)
      ParticipantIssue.classification,
  ];

  @override
  List<String> get classes =>
      distinctClasses(rows.map((row) => row.classification));

  @override
  List<TeamSummary> get teams => summarizeTeams(rows.map((row) => row.team));

  @override
  String normalizeTeam(String typed) => normalizeTeamName(typed, teams);

  @override
  String get numberHeader => drawn ? 'Pilot no.' : 'Pilot no. (provisional)';

  /// Before the draw, the provisional number (scoring pilots in list order).
  /// After it, the allocated number, or `Not placed yet` for someone added
  /// since.
  @override
  String numberLabel(ParticipantRow row) {
    if (!isScoring(row)) {
      return '—';
    }
    final stored = row as StoredParticipant;
    if (drawn) {
      return stored.number?.toString() ?? 'Not placed yet';
    }
    final pilots = rows.where(isScoring).toList();
    final index = pilots.indexWhere((p) => p.rowId == row.rowId);
    return '${index + 1} · provisional';
  }
}
