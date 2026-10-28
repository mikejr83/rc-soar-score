import '../participants/participant_option.dart';
import '../participants/participant_row.dart';
import 'contest_draft.dart';
import 'draft_participant.dart';
import 'participant_rules.dart';

/// The participant list rules answered from a wizard draft.
class DraftListRules implements ParticipantListRules {
  const DraftListRules(this.draft);

  final ContestDraft draft;

  @override
  bool has(ParticipantOption option) => draft.has(option);

  @override
  bool isScoring(ParticipantRow row) =>
      draft.isScoring(row as DraftParticipant);

  @override
  List<ParticipantIssue> issuesOf(ParticipantRow row) =>
      draft.issuesOf(row as DraftParticipant);

  @override
  List<String> get classes => draft.classes;

  @override
  List<TeamSummary> get teams => draft.teams;

  @override
  String normalizeTeam(String typed) => draft.normalizeTeam(typed);

  /// The provisional pilot number: scoring pilots in list order. Numbers
  /// are assigned at the first draw.
  @override
  String numberLabel(ParticipantRow row) {
    if (!isScoring(row)) {
      return '—';
    }
    final pilots = draft.participants.where(draft.isScoring).toList();
    final index = pilots.indexWhere((p) => p.rowId == row.rowId);
    return '${index + 1} · provisional';
  }
}
