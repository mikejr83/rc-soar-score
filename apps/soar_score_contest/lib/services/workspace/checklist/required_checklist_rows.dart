import '../workspace_facts.dart';
import 'checklist_item.dart';

/// The four rows that must be done before the contest can run.
abstract final class RequiredChecklistRows {
  /// Configuration saved and valid.
  static ChecklistItem configuration(
    WorkspaceFacts facts,
    String Function(DateTime savedAt) formatSavedAt,
  ) {
    final configuration = facts.configuration;
    if (configuration == null) {
      return const ChecklistItem(
        id: ChecklistItemId.configuration,
        status: ChecklistStatus.todo,
        title: 'Configuration not saved',
        detail: 'Choose scoring options and save them.',
        target: ChecklistTarget.configuration,
      );
    }
    final problem = facts.configurationProblem;
    if (problem != null) {
      return ChecklistItem(
        id: ChecklistItemId.configuration,
        status: ChecklistStatus.missing,
        title: 'Configuration needs attention',
        detail: problem,
        target: ChecklistTarget.configuration,
      );
    }
    return ChecklistItem(
      id: ChecklistItemId.configuration,
      status: ChecklistStatus.done,
      title: 'Configuration saved and valid',
      detail:
          'Revision ${configuration.revisionNumber} · saved '
          '${formatSavedAt(configuration.createdAt)}',
      target: ChecklistTarget.configuration,
    );
  }

  /// Discipline and landing table chosen.
  static ChecklistItem discipline(WorkspaceFacts facts) {
    const title = 'Discipline and landing table';
    final configuration = facts.configuration;
    if (configuration == null) {
      return const ChecklistItem(
        id: ChecklistItemId.discipline,
        status: ChecklistStatus.todo,
        title: title,
        detail:
            'The discipline and landing table are saved with the '
            'configuration.',
        target: ChecklistTarget.configuration,
      );
    }
    if (configuration.landingTableId == null) {
      return ChecklistItem(
        id: ChecklistItemId.discipline,
        status: ChecklistStatus.check,
        title: title,
        detail:
            '${facts.disciplineLabel ?? 'Discipline'} · no landing table '
            'chosen',
        target: ChecklistTarget.configuration,
      );
    }
    final rules = facts.houseRuleCount;
    return ChecklistItem(
      id: ChecklistItemId.discipline,
      status: ChecklistStatus.done,
      title: title,
      detail: [
        facts.disciplineLabel ?? 'Discipline',
        facts.landingTableName ?? 'Landing table chosen',
        rules == 0 ? 'no house rules' : _count(rules, 'house rule'),
      ].join(' · '),
      target: ChecklistTarget.configuration,
    );
  }

  /// At least two scoring pilots.
  static ChecklistItem pilots(WorkspaceFacts facts) {
    final count = facts.scoringPilots;
    final setup = _participantSetup(facts);
    if (count < 2) {
      return ChecklistItem(
        id: ChecklistItemId.pilots,
        status: ChecklistStatus.missing,
        title: count == 0 ? 'No scoring pilots' : '1 scoring pilot',
        detail: ['At least 2 are needed.', ?setup].join(' '),
        target: ChecklistTarget.participants,
      );
    }
    return ChecklistItem(
      id: ChecklistItemId.pilots,
      status: ChecklistStatus.done,
      title: '$count scoring pilots',
      detail: setup ?? 'Ready to fly.',
      target: ChecklistTarget.participants,
    );
  }

  /// The matrix drawn, and still matching the configuration.
  static ChecklistItem matrix(WorkspaceFacts facts) {
    if (!facts.hasMatrix) {
      return ChecklistItem(
        id: ChecklistItemId.matrix,
        status: ChecklistStatus.todo,
        title: 'Matrix not drawn',
        detail: _drawNote(facts),
        target: ChecklistTarget.matrix,
      );
    }
    final summary = _matrixSummary(facts);
    if (facts.configDrift.isNotEmpty) {
      return ChecklistItem(
        id: ChecklistItemId.matrix,
        status: ChecklistStatus.check,
        title: 'Matrix doesn’t match the configuration',
        detail: '${facts.configDrift.join(' ')} $summary',
        target: ChecklistTarget.matrix,
      );
    }
    return ChecklistItem(
      id: ChecklistItemId.matrix,
      status: ChecklistStatus.done,
      title: 'Matrix drawn',
      detail: summary,
      target: ChecklistTarget.matrix,
    );
  }

  // "Teams off · classes off" when the options are known; `null` when the
  // configuration is missing or invalid, so nothing is guessed.
  static String? _participantSetup(WorkspaceFacts facts) {
    final options = facts.options;
    if (options == null) {
      return null;
    }
    final teams = options.teamsEnabled
        ? _count(facts.teamCount, 'team')
        : 'teams off';
    final classes = options.classesEnabled ? 'classes on' : 'classes off';
    final text = '$teams · $classes';
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  static String _matrixSummary(WorkspaceFacts facts) {
    final revision = facts.matrix.revision?.revisionNumber;
    final sizes = facts.groupSizeMin == facts.groupSizeMax
        ? '${facts.groupSizeMax}'
        : '${facts.groupSizeMin} to ${facts.groupSizeMax}';
    return [
      ?revision == null ? null : 'Revision $revision',
      _count(facts.roundCount, 'round'),
      '${_count(facts.groupCount, 'group')} of $sizes',
    ].join(' · ');
  }

  // Ready to draw, or what stands in the way.
  static String _drawNote(WorkspaceFacts facts) {
    if (facts.drawReadiness.enabled) {
      return 'Ready to draw on the Matrix page.';
    }
    final earlierDone =
        facts.configuration != null &&
        facts.configurationProblem == null &&
        facts.scoringPilots >= 2;
    final blocker = facts.drawReadiness.first;
    if (earlierDone && blocker != null) {
      return blocker.text;
    }
    return 'Can be drawn once the items above are done.';
  }

  static String _count(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';
}
