import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/matrix_page_data.dart';
import 'score_entry_settings.dart';
import 'score_grid_options.dart';
import 'scoring_completeness.dart';
import 'scoring_row.dart';

/// Why entry is closed for a group, with the words the page shows beside the
/// disabled controls.
enum EntryBlock {
  contestCompleted(
    'Contest completed',
    'This contest is completed. Scores cannot be entered.',
  ),
  administrationLocked(
    'Administration locked',
    'Administration is locked. Unlock it to enter or correct scores.',
  ),
  roundLocked('Round locked', 'This round is locked.'),
  groupLocked('Group locked', 'This group is locked.');

  const EntryBlock(this.chip, this.message);

  /// The short words for the context chip.
  final String chip;
  final String message;
}

/// Everything the scoring page shows about one contest: the matrix page's
/// data, plus the scores, the landing table and the contest's entry settings.
class ScoringPageData {
  ScoringPageData({
    required this.base,
    required this.scores,
    required this.landings,
    this.landingTableName,
  }) : settings = ScoreEntrySettings.fromDiscipline(
         base.configuration?.config.discipline,
       ),
       _slots = {
         for (final slot in scores.slots) slot.placeholder.assignmentId: slot,
       };

  /// Loads the contest, the matrix, the scores and the landing table.
  static Future<ScoringPageData> load(ApiClient client, Id id) async {
    final results = await Future.wait<Object?>([
      MatrixPageData.load(client, id),
      client.scores(id),
      client.landingTables(),
    ]);
    final base = results[0]! as MatrixPageData;
    final tables = results[2]! as List<LandingTableView>;
    final tableId = base.configuration?.landingTableId;
    final landings = <LandingResult>[];
    String? tableName;
    for (final view in tables) {
      if (view.table.id == tableId) {
        landings.addAll(view.results);
        tableName = view.table.name;
      }
    }
    landings.sort((a, b) => a.ordinalPosition.compareTo(b.ordinalPosition));
    return ScoringPageData(
      base: base,
      scores: results[1]! as ContestScores,
      landings: landings,
      landingTableName: tableName,
    );
  }

  final MatrixPageData base;
  final ContestScores scores;

  /// The lane or number column and the teams this contest shows.
  ScoreGridOptions get gridOptions {
    final lanes = (base.options?.laneMode ?? LaneMode.none) != LaneMode.none;
    return ScoreGridOptions(
      idLabel: lanes ? 'Lane' : (base.showNumbers ? 'No.' : null),
      showTeams: base.showTeams,
    );
  }

  /// The choices of the contest's landing table, in table order.
  final List<LandingResult> landings;

  /// The landing table's name, shown over the landing choice.
  final String? landingTableName;

  final ScoreEntrySettings settings;
  final Map<Id, ScoreSlot> _slots;

  Contest get contest => base.contest;
  CurrentMatrix get matrix => base.matrix;
  List<Round> get rounds =>
      [...matrix.rounds]..sort((a, b) => a.ordinal.compareTo(b.ordinal));

  Round? roundByOrdinal(int ordinal) {
    for (final round in matrix.rounds) {
      if (round.ordinal == ordinal) return round;
    }
    return null;
  }

  /// The group numbers of [round], from 1.
  List<int> groupNumbers(Round round) => [
    for (var n = 1; n <= round.groupCount; n++) n,
  ];

  RoundGroup? groupOf(Round round, int number) {
    for (final group in matrix.groups) {
      if (group.roundId == round.id && group.groupNumber == number) {
        return group;
      }
    }
    return null;
  }

  /// The assignments of one group, as scoring rows. Lane order when the draw
  /// gave lanes, otherwise pilot number, then name.
  List<ScoringRow> rowsOf(
    Round round,
    int group, {
    Map<Id, FlightResult> results = const {},
  }) {
    final pilots = base.pilots;
    final locked = block(round, group) != null;
    final rows = <ScoringRow>[];
    for (final assignment in matrix.assignments) {
      if (assignment.scheduledRoundId != round.id ||
          assignment.group != group ||
          assignment.supersededByAssignmentId != null) {
        continue;
      }
      final pilot = pilots[assignment.contestParticipationId];
      if (pilot == null) continue;
      rows.add(
        ScoringRow(
          assignment: assignment,
          pilot: pilot,
          slot: _slots[assignment.id],
          team: base.markers.of(pilot.teamId),
          result: results[assignment.contestParticipationId],
          locked: locked,
        ),
      );
    }
    rows.sort((a, b) {
      final lane = (a.lane ?? 1 << 20).compareTo(b.lane ?? 1 << 20);
      if (lane != 0) return lane;
      final number = (a.pilot.number ?? 1 << 20).compareTo(
        b.pilot.number ?? 1 << 20,
      );
      return number != 0 ? number : a.pilot.name.compareTo(b.pilot.name);
    });
    return rows;
  }

  /// Why entry is closed for [group] of [round], or null when it is open.
  EntryBlock? block(Round round, int group) {
    if (contest.lifecycleState == LifecycleState.completed) {
      return EntryBlock.contestCompleted;
    }
    if (contest.adminLock == AdminLock.locked) {
      return EntryBlock.administrationLocked;
    }
    if (round.status == RoundStatus.locked) return EntryBlock.roundLocked;
    if (groupOf(round, group)?.status == GroupStatus.locked) {
      return EntryBlock.groupLocked;
    }
    return null;
  }

  /// How complete [group] of [round] is, for the pickers.
  Completeness groupCompleteness(Round round, int group) {
    final rows = rowsOf(round, group);
    return Completeness.of(
      total: rows.length,
      scored: rows.where((r) => r.isScored).length,
      official: rows.where((r) => r.status == RowStatus.official).length,
      locked: block(round, group) != null && rows.isNotEmpty,
    );
  }

  /// How complete [round] is, from every group.
  Completeness roundCompleteness(Round round) {
    var total = 0;
    var scored = 0;
    var official = 0;
    var allLocked = round.groupCount > 0;
    for (final group in groupNumbers(round)) {
      final rows = rowsOf(round, group);
      total += rows.length;
      scored += rows.where((r) => r.isScored).length;
      official += rows.where((r) => r.status == RowStatus.official).length;
      if (block(round, group) == null) allLocked = false;
    }
    return Completeness.of(
      total: total,
      scored: scored,
      official: official,
      locked: allLocked && total > 0,
    );
  }

  /// The slots after one save: [slot] replaces the one it belongs to.
  ScoringPageData withSlot(ScoreSlot slot) {
    final slots = [
      for (final existing in scores.slots)
        if (existing.placeholder.assignmentId == slot.placeholder.assignmentId)
          slot
        else
          existing,
    ];
    return ScoringPageData(
      base: base,
      scores: ContestScores(slots: slots, rounds: scores.rounds),
      landings: landings,
      landingTableName: landingTableName,
    );
  }

  /// This data with the contest after a score entry moved it to Running.
  ScoringPageData withContest(Contest contest) => ScoringPageData(
    base: MatrixPageData(
      contest: contest,
      configuration: base.configuration,
      participations: base.participations,
      profiles: base.profiles,
      teams: base.teams,
      memberships: base.memberships,
      matrix: base.matrix,
    ),
    scores: scores,
    landings: landings,
    landingTableName: landingTableName,
  );

  /// The round and group to open when the route names none: the first group
  /// that is not completely scored, else the first.
  (int round, int group) get firstOpen {
    for (final round in rounds) {
      for (final group in groupNumbers(round)) {
        final c = groupCompleteness(round, group);
        if (c.total > 0 && c.scored < c.total) return (round.ordinal, group);
      }
    }
    final first = rounds.isEmpty ? null : rounds.first;
    return (first?.ordinal ?? 1, 1);
  }
}
