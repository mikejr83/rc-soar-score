import 'dart:math' as math;

import '../models/imports/draw_import_draft.dart';
import '../models/imports/glider_score_import_result.dart';
import 'glider_score_contest_mapper.dart';

/// Turns the `Scores` table of a GliderScore database into the draw of a
/// competition that phase B already imported as a contest.
///
/// GliderScore has no draw table: the draw is the set of `Scores` rows, one
/// per drawn flight, scored or not (`Updated`). The mapping rules are in the
/// phase C plan and the ADR 0006 amendment:
///
/// - one revision per run of consecutive rounds of one task with the same
///   number of groups, chained as extensions;
/// - observed groups win over the configured groups per round;
/// - lane count above 0: lane = rank of `SeqNo` in the group; 0: no lanes;
/// - every `Scores` field is kept in a [FlightDraft] for phase D.
///
/// Pure: no I/O, never throws on odd input. A refused competition comes back
/// with a reason code and the others proceed.
class GliderScoreDrawMapper {
  const GliderScoreDrawMapper({this.supportedClasses = const {'F5J'}});

  /// The `GSCompClass` values a draw is imported for.
  final Set<String> supportedClasses;

  /// The tag stored as the revision's `algorithm_version`.
  static const algorithmVersion = 'import:gliderscore/1';

  /// The draw of every target, in `CompNo` order.
  List<DrawImportDraft> map(
    GliderScoreImportResult result,
    Iterable<DrawImportTarget> targets,
  ) {
    final ordered = targets.toList()
      ..sort((a, b) => a.sourceCompNo.compareTo(b.sourceCompNo));
    return [for (final t in ordered) mapCompetition(result, t)];
  }

  DrawImportDraft mapCompetition(
    GliderScoreImportResult result,
    DrawImportTarget target,
  ) {
    final no = target.sourceCompNo;
    DrawImportDraft refused(
      String reason, {
      String? detail,
      int laneCount = 0,
      bool teamProtection = false,
    }) => DrawImportDraft(
      sourceCompNo: no,
      status: DrawImportStatus.refused,
      reason: reason,
      reasonDetail: detail,
      laneCount: laneCount,
      teamProtection: teamProtection,
    );

    // The contest side first: nothing about the file matters otherwise.
    if (!target.stamped) {
      return refused(DrawImportReason.notStamped);
    }
    if (target.stampedFingerprint != target.fileFingerprint) {
      return refused(DrawImportReason.fingerprintChanged);
    }
    if (target.hasMatrix) {
      return refused(DrawImportReason.alreadyDrawn);
    }
    if (target.hasAcceptedScores) {
      return refused(DrawImportReason.hasAcceptedScores);
    }

    final comp = _rowFor(_table(result, 'Comps'), no);
    if (comp == null) {
      return refused(DrawImportReason.competitionMissing);
    }
    final sourceClass = GliderScoreContestMapper.text(comp['GSCompClass']);
    if (sourceClass == null || !supportedClasses.contains(sourceClass)) {
      return refused(DrawImportReason.classNotSupported, detail: sourceClass);
    }
    final configuredGroups = GliderScoreContestMapper.number(
      _rowFor(_table(result, 'Dur'), no)?['durGroupsPerRound'],
    )?.toInt();
    final laneCount = math.max(
      0,
      GliderScoreContestMapper.number(
            _rowFor(_table(result, 'Dur'), no)?['durNbrOfLanes'],
          )?.toInt() ??
          0,
    );
    final teamProtection =
        GliderScoreContestMapper.flag(comp['UseTeams']) &&
        GliderScoreContestMapper.flag(comp['UseTeamProtection']);

    DrawImportDraft refuse(String reason, [String? detail]) => refused(
      reason,
      detail: detail,
      laneCount: laneCount,
      teamProtection: teamProtection,
    );

    final scores = _table(result, 'Scores');
    if (scores == null || scores.rowCapExceeded) {
      return refuse(DrawImportReason.scoresUnavailable);
    }

    // The competition's rows, as flights.
    final flights = <FlightDraft>[];
    for (final row in scores.rows) {
      if (GliderScoreContestMapper.number(row['CompNo'])?.toInt() != no) {
        continue;
      }
      final flight = _flight(row);
      if (flight == null) {
        return refuse(DrawImportReason.keyMissing);
      }
      flights.add(flight);
    }
    if (flights.isEmpty) {
      return refuse(DrawImportReason.noDraw);
    }
    flights.sort(_byDraw);

    final strangers = {
      for (final f in flights)
        if (!target.participantPilotNos.contains(f.sourcePilotNo))
          f.sourcePilotNo,
    }.toList()..sort();
    if (strangers.isNotEmpty) {
      return refuse(
        DrawImportReason.pilotWithoutParticipation,
        strangers.join(','),
      );
    }
    final moved = flights.where(
      (f) => f.originalRoundNo != null && f.originalRoundNo != f.roundNo,
    );
    if (moved.isNotEmpty) {
      final f = moved.first;
      return refuse(
        DrawImportReason.creditMoved,
        'pilot ${f.sourcePilotNo} round ${f.roundNo} credited to '
        '${f.originalRoundNo}',
      );
    }

    // First flights are the draw; re-flights must repeat one of them.
    final drawn = flights.where((f) => !f.isReflight).toList();
    final slots = <String>{};
    for (final f in drawn) {
      if (!slots.add('${f.roundNo}/${f.sourcePilotNo}')) {
        return refuse(
          DrawImportReason.duplicateFlight,
          'pilot ${f.sourcePilotNo} round ${f.roundNo}',
        );
      }
    }
    for (final f in flights.where((f) => f.isReflight)) {
      if (!slots.contains('${f.roundNo}/${f.sourcePilotNo}')) {
        return refuse(
          DrawImportReason.reflightWithoutOriginal,
          'pilot ${f.sourcePilotNo} round ${f.roundNo}',
        );
      }
    }
    if (drawn.isEmpty) {
      return refuse(DrawImportReason.noDraw);
    }

    // Rounds must run 1..N and each task must hold a contiguous block.
    final taskOfRound = <int, int>{};
    for (final f in drawn) {
      final earlier = taskOfRound.putIfAbsent(f.roundNo, () => f.taskNo);
      if (earlier != f.taskNo) {
        return refuse(
          DrawImportReason.taskRangesOverlap,
          'round ${f.roundNo} in tasks $earlier and ${f.taskNo}',
        );
      }
    }
    final roundNos = taskOfRound.keys.toList()..sort();
    for (var i = 0; i < roundNos.length; i++) {
      if (roundNos[i] != i + 1) {
        return refuse(
          DrawImportReason.taskRangesGapped,
          'round ${i + 1} is missing',
        );
      }
    }
    final tasks = <int>[];
    for (final r in roundNos) {
      final t = taskOfRound[r]!;
      if (tasks.isNotEmpty && tasks.last != t) {
        if (tasks.contains(t)) {
          return refuse(
            DrawImportReason.taskRangesOverlap,
            'task $t is split by task ${tasks.last}',
          );
        }
      }
      if (tasks.isEmpty || tasks.last != t) {
        tasks.add(t);
      }
    }

    final warnings = <DrawImportWarning>[
      const DrawImportWarning(DrawImportWarning.notReproducible),
    ];

    // Build the rounds.
    final rounds = <RoundDraft>[];
    final groupsOf = <int, int>{};
    for (final roundNo in roundNos) {
      final inRound = drawn.where((f) => f.roundNo == roundNo).toList();
      final groupCount = inRound.map((f) => f.groupNo).reduce(math.max);
      groupsOf[roundNo] = groupCount;
      if (configuredGroups != null && configuredGroups != groupCount) {
        warnings.add(
          DrawImportWarning(
            DrawImportWarning.groupsPerRoundDiffers,
            round: roundNo,
            detail: 'configured $configuredGroups, drawn $groupCount',
          ),
        );
      }
      final groups = <GroupDraft>[];
      final sizes = <int>[];
      for (var g = 1; g <= groupCount; g++) {
        final members = inRound.where((f) => f.groupNo == g).toList();
        if (members.isEmpty) {
          warnings.add(
            DrawImportWarning(
              DrawImportWarning.emptyGroup,
              round: roundNo,
              detail: '$g',
            ),
          );
        }
        sizes.add(members.length);
        groups.add(
          GroupDraft(
            groupNo: g,
            assignments: _assign(
              members,
              laneCount: laneCount,
              round: roundNo,
              warnings: warnings,
            ),
          ),
        );
      }
      if (!_matchesDerived(sizes)) {
        warnings.add(
          DrawImportWarning(
            DrawImportWarning.groupSizesDiffer,
            round: roundNo,
            detail: sizes.join('/'),
          ),
        );
      }
      rounds.add(RoundDraft(ordinal: roundNo, groups: groups));
    }

    // One revision per run of rounds with the same task and group count.
    final revisions = <RevisionDraft>[];
    var start = 0;
    for (var i = 1; i <= rounds.length; i++) {
      final atEnd = i == rounds.length;
      if (!atEnd &&
          taskOfRound[rounds[i].ordinal] ==
              taskOfRound[rounds[start].ordinal] &&
          groupsOf[rounds[i].ordinal] == groupsOf[rounds[start].ordinal]) {
        continue;
      }
      final run = rounds.sublist(start, i);
      revisions.add(
        RevisionDraft(
          revisionNumber: revisions.length + 1,
          taskNo: taskOfRound[run.first.ordinal]!,
          firstRound: run.first.ordinal,
          lastRound: run.last.ordinal,
          groupsPerRound: groupsOf[run.first.ordinal]!,
          rounds: run,
        ),
      );
      start = i;
    }

    final lastFlown = flights
        .where((f) => f.scored)
        .map((f) => f.roundNo)
        .fold<int>(0, math.max);

    return DrawImportDraft(
      sourceCompNo: no,
      status: DrawImportStatus.importable,
      laneCount: laneCount,
      teamProtection: teamProtection,
      revisions: revisions,
      flights: flights,
      probablyUnflownRounds: [
        for (final r in roundNos)
          if (r > lastFlown) r,
      ],
      warnings: warnings,
    );
  }

  /// Orders one group's first flights by `SeqNo` and gives each its rank.
  List<AssignmentDraft> _assign(
    List<FlightDraft> members, {
    required int laneCount,
    required int round,
    required List<DrawImportWarning> warnings,
  }) {
    final ordered = [...members]
      ..sort((a, b) {
        // Flights without a SeqNo go last.
        final sa = a.seqNo ?? 1 << 30;
        final sb = b.seqNo ?? 1 << 30;
        final c = sa.compareTo(sb);
        return c != 0 ? c : a.sourcePilotNo.compareTo(b.sourcePilotNo);
      });
    final seen = <int>{};
    final out = <AssignmentDraft>[];
    for (var i = 0; i < ordered.length; i++) {
      final f = ordered[i];
      final seq = f.seqNo;
      if (seq == null) {
        warnings.add(
          DrawImportWarning(
            DrawImportWarning.seqNoMissing,
            round: round,
            sourcePilotNo: f.sourcePilotNo,
          ),
        );
      } else if (!seen.add(seq)) {
        warnings.add(
          DrawImportWarning(
            DrawImportWarning.seqNoDuplicate,
            round: round,
            sourcePilotNo: f.sourcePilotNo,
            detail: '$seq',
          ),
        );
      }
      final position = i + 1;
      if (laneCount > 0 && position > laneCount) {
        warnings.add(
          DrawImportWarning(
            DrawImportWarning.laneBeyondLaneCount,
            round: round,
            sourcePilotNo: f.sourcePilotNo,
            detail: 'lane $position of $laneCount',
          ),
        );
      }
      out.add(
        AssignmentDraft(
          sourcePilotNo: f.sourcePilotNo,
          seqNo: seq,
          position: position,
          lane: laneCount > 0 ? position : null,
        ),
      );
    }
    return out;
  }

  /// True when [sizes] (one per group) are what Soar Score derives from the
  /// pilot count and the number of groups: the first `N mod G` groups one
  /// pilot larger, in any order of groups.
  static bool _matchesDerived(List<int> sizes) {
    if (sizes.isEmpty) {
      return true;
    }
    final n = sizes.fold(0, (a, b) => a + b);
    final g = sizes.length;
    final derived = [for (var i = 0; i < g; i++) n ~/ g + (i < n % g ? 1 : 0)]
      ..sort();
    final actual = [...sizes]..sort();
    for (var i = 0; i < g; i++) {
      if (derived[i] != actual[i]) {
        return false;
      }
    }
    return true;
  }

  static int _byDraw(FlightDraft a, FlightDraft b) {
    final c = [
      a.roundNo.compareTo(b.roundNo),
      a.reflightNo.compareTo(b.reflightNo),
      a.groupNo.compareTo(b.groupNo),
      (a.seqNo ?? 1 << 30).compareTo(b.seqNo ?? 1 << 30),
      a.sourcePilotNo.compareTo(b.sourcePilotNo),
    ].firstWhere((v) => v != 0, orElse: () => 0);
    return c;
  }

  static FlightDraft? _flight(Map<String, Object?> row) {
    int? integer(String key) =>
        GliderScoreContestMapper.number(row[key])?.toInt();
    num? n(String key) => GliderScoreContestMapper.number(row[key]);
    final task = integer('TaskNo');
    final round = integer('RoundNo');
    final group = integer('GroupNo');
    final pilot = integer('PilotNo');
    if (task == null ||
        round == null ||
        group == null ||
        pilot == null ||
        round < 1 ||
        group < 1) {
      return null;
    }
    return FlightDraft(
      taskNo: task,
      roundNo: round,
      groupNo: group,
      reflightNo: integer('ReFlightNo') ?? 0,
      sourcePilotNo: pilot,
      scored: GliderScoreContestMapper.flag(row['Updated']),
      seqNo: integer('SeqNo'),
      originalRoundNo: integer('OriginalRoundNo'),
      drawFrequency: n('DrawFreq'),
      time1Mins: n('Time1Mins'),
      time1Secs: n('Time1Secs'),
      time2Mins: n('Time2Mins'),
      time2Secs: n('Time2Secs'),
      flightScoreDeduction: n('FlightScoreDeduction'),
      landing: n('Landing'),
      rawScore: n('RawScore'),
      normalisedScore: n('NormalisedScore'),
      penalty: n('Penalty'),
      scoresChecked: n('ScoresChecked'),
      landingOver75m: n('LandingOver75m'),
      helper: n('Helper'),
      laps: n('Laps'),
      motorRestarted: n('F5JMotorReStarted'),
    );
  }

  static GliderScoreTable? _table(GliderScoreImportResult r, String name) {
    for (final table in r.tables) {
      if (table.name.toLowerCase() == name.toLowerCase()) {
        return table;
      }
    }
    return null;
  }

  static Map<String, Object?>? _rowFor(GliderScoreTable? table, int compNo) {
    for (final row in table?.rows ?? const <Map<String, Object?>>[]) {
      if (GliderScoreContestMapper.number(row['CompNo'])?.toInt() == compNo) {
        return row;
      }
    }
    return null;
  }
}
