import 'dart:convert';
import 'dart:math' as math;

import '../enums/re_flight_participant_role.dart';
import '../import/stable_hash.dart';
import '../models/imports/contest_import_draft.dart';
import '../models/imports/draw_import_draft.dart';
import '../models/imports/glider_score_import_result.dart';
import '../models/imports/restore_plan.dart';
import 'glider_score_contest_mapper.dart';
import 'glider_score_draw_mapper.dart';
import 'glider_score_score_mapping.dart';

/// Turns a GliderScore database into one [RestorePlan] per competition: the
/// contest and participants (phase B's rules), the draw (phase C's), every
/// scored flight, the re-flights, the retirements, the landing table and the
/// state the contest ends in.
///
/// The import is a point-in-time restore (ADR 0006, amendment 2): one plan
/// holds everything, whether the contest is created or updated in place.
///
/// Pure: no I/O, never throws on odd input. A competition that cannot be
/// restored comes back refused, with a reason code, and the others proceed.
class GliderScoreRestoreMapper {
  const GliderScoreRestoreMapper({
    this.contestMapper = const GliderScoreContestMapper(),
    this.drawMapper = const GliderScoreDrawMapper(),
  });

  final GliderScoreContestMapper contestMapper;
  final GliderScoreDrawMapper drawMapper;

  /// How many flights a refusal names.
  static const detailLimit = 5;

  /// The plan of every competition of [result], in `CompNo` order.
  List<RestorePlan> map(GliderScoreImportResult result) =>
      mapContests(result, contestMapper.map(result).contests);

  /// The plans of [contests], which were mapped from [result].
  List<RestorePlan> mapContests(
    GliderScoreImportResult result,
    Iterable<ContestImportDraft> contests,
  ) => [for (final c in contests) mapCompetition(result, c)];

  RestorePlan mapCompetition(
    GliderScoreImportResult result,
    ContestImportDraft contest,
  ) {
    final identity = RestoreIdentity(
      compNo: contest.sourceCompNo,
      compId: contest.sourceCompId,
      name: contest.name,
      date: _dateKey(contest.startDate),
    );
    RestorePlan refused(
      String reason, {
      String? detail,
      DrawImportDraft? draw,
    }) => RestorePlan(
      sourceCompNo: contest.sourceCompNo,
      identity: identity,
      status: RestoreStatus.refused,
      contest: contest,
      reason: reason,
      reasonDetail: detail,
      draw: draw,
    );

    if (!contest.isImportable) {
      return refused(
        contest.reason ?? ContestImportReason.configInvalid,
        detail: contest.reasonDetail,
      );
    }
    final scoreMapper =
        contestMapper.classMappers[contest.sourceClass]?.scoreMapper;
    if (scoreMapper == null) {
      return refused(
        RestoreReason.classNotSupported,
        detail: contest.sourceClass,
      );
    }

    // The draw, with the guards that belonged to filling a phase B contest
    // switched off: the plan creates the participants itself.
    const fingerprint = 'restore';
    final draw = drawMapper.mapCompetition(
      result,
      DrawImportTarget(
        sourceCompNo: contest.sourceCompNo,
        fileFingerprint: fingerprint,
        stampedFingerprint: fingerprint,
        participantPilotNos: {
          for (final p in contest.participants) p.sourcePilotNo,
        },
      ),
    );
    if (!draw.isImportable) {
      return refused(
        draw.reason ?? DrawImportReason.noDraw,
        detail: draw.reasonDetail,
        draw: draw,
      );
    }

    final warnings = <RestoreWarning>[];
    final durRow = _row(result, 'Dur', contest.sourceCompNo);
    final restartOption = GliderScoreContestMapper.number(
      durRow?['F5JMotorRestartOption'],
    )?.toInt();
    final workingTime =
        GliderScoreContestMapper.number(durRow?['durTargetTime']) ??
        contest.config?.discipline['working_time'] as num? ??
        600;

    final scored = draw.flights.where((f) => f.scored).toList();

    // The landing table the competition used.
    final tableNo = GliderScoreContestMapper.number(durRow?['durLndg'])
        ?.toInt();
    final landing = scoreMapper.selectLanding(
      sourceTableNo: tableNo != null && tableNo != 0 ? tableNo : null,
      sourceTableName: _landingName(result, tableNo),
      tableRows: _landingRows(result, tableNo),
      observed: {
        for (final f in scored)
          if ((f.landing ?? 0) != 0) f.landing!.toInt(),
      },
    );
    if (landing.match == LandingMatch.partial) {
      warnings.add(
        RestoreWarning(
          RestoreWarning.landingPartialMatch,
          detail: 'unresolved ${landing.unresolved.toList()..sort()}',
        ),
      );
    }

    // Groups: the regular groups of each round, and the flown group of each
    // re-flight after them.
    final regularGroups = <int, int>{};
    for (final revision in draw.revisions) {
      for (final round in revision.rounds) {
        regularGroups[round.ordinal] = round.groups.length;
      }
    }
    final drawn = {
      for (final f in draw.flights)
        if (!f.isReflight) '${f.roundNo}/${f.groupNo}/${f.sourcePilotNo}': f,
    };

    // Re-flights: whole groups only.
    final cells = <(int, int, int), List<FlightDraft>>{};
    for (final f in draw.flights.where((f) => f.isReflight)) {
      (cells[(f.roundNo, f.reflightNo, f.groupNo)] ??= []).add(f);
    }
    final cellKeys = cells.keys.toList()
      ..sort((a, b) {
        for (var i = 0; i < 3; i++) {
          final c = [a.$1, a.$2, a.$3][i].compareTo([b.$1, b.$2, b.$3][i]);
          if (c != 0) return c;
        }
        return 0;
      });
    final reflights = <ReflightDraft>[];
    final flownGroupOf = <(int, int, int), int>{};
    final used = <int, int>{};
    for (final key in cellKeys) {
      final (round, reflightNo, group) = key;
      final members = cells[key]!;
      final originalRows = [
        for (final f in draw.flights)
          if (!f.isReflight && f.roundNo == round && f.groupNo == group)
            f.sourcePilotNo,
      ];
      final original = originalRows.toSet();
      final again = {for (final f in members) f.sourcePilotNo};
      // A repeated pilot in either list is a malformed file, not a group.
      if (originalRows.length != original.length ||
          members.length != again.length ||
          original.length != again.length ||
          !original.containsAll(again)) {
        return refused(
          RestoreReason.reflightNotWholeGroup,
          detail: 'round $round group $group re-flight $reflightNo',
          draw: draw,
        );
      }
      final flown =
          (regularGroups[round] ?? 0) + (used[round] = (used[round] ?? 0) + 1);
      flownGroupOf[key] = flown;
      final ordered = [...members]
        ..sort((a, b) {
          final c = (a.seqNo ?? 1 << 30).compareTo(b.seqNo ?? 1 << 30);
          return c != 0 ? c : a.sourcePilotNo.compareTo(b.sourcePilotNo);
        });
      final out = <ReflightMemberDraft>[];
      for (var i = 0; i < ordered.length; i++) {
        final f = ordered[i];
        final before = drawn['$round/$group/${f.sourcePilotNo}'];
        final awarded = before == null || !before.scored;
        if (awarded) {
          warnings.add(
            RestoreWarning(
              RestoreWarning.reflightAwarded,
              round: round,
              group: group,
              sourcePilotNo: f.sourcePilotNo,
            ),
          );
        }
        out.add(
          ReflightMemberDraft(
            sourcePilotNo: f.sourcePilotNo,
            role: awarded
                ? ReFlightParticipantRole.awarded
                : ReFlightParticipantRole.groupMember,
            position: i + 1,
            scored: f.scored,
          ),
        );
      }
      reflights.add(
        ReflightDraft(
          taskNo: members.first.taskNo,
          roundNo: round,
          reflightNo: reflightNo,
          sourceGroupNo: group,
          flownGroupNo: flown,
          members: out,
        ),
      );
    }

    // The scored flights.
    final context = ScoreMappingContext(
      restartOption: restartOption,
      workingTimeSeconds: workingTime,
      landing: landing,
    );
    final flights = <RestoredFlight>[];
    final broken = <String>[];
    for (final f in scored) {
      final values = scoreMapper.mapFlight(f, context);
      if (values.isRefused) {
        broken.add(
          'round ${f.roundNo} group ${f.groupNo} pilot ${f.sourcePilotNo}: '
          '${values.refusal}${values.refusalDetail == null ? '' : ' ${values.refusalDetail}'}',
        );
        continue;
      }
      warnings.addAll(values.warnings);
      flights.add(
        RestoredFlight(
          taskNo: f.taskNo,
          roundNo: f.roundNo,
          sourceGroupNo: f.groupNo,
          groupNo: f.isReflight
              ? flownGroupOf[(f.roundNo, f.reflightNo, f.groupNo)]!
              : f.groupNo,
          reflightNo: f.reflightNo,
          sourcePilotNo: f.sourcePilotNo,
          kind: values.kind,
          components: values.components,
          rawComponents: values.rawComponents,
          sourceRawScore: f.rawScore,
        ),
      );
    }
    if (broken.isNotEmpty) {
      return refused(
        RestoreReason.flightNotRepresentable,
        detail:
            '${broken.length} flight(s): '
            '${broken.take(detailLimit).join('; ')}',
        draw: draw,
      );
    }

    // Retirements: the round after the pilot's last scored flight.
    final lastScored = <int, int>{};
    for (final f in scored) {
      lastScored[f.sourcePilotNo] = math.max(
        lastScored[f.sourcePilotNo] ?? 0,
        f.roundNo,
      );
    }
    final retirements = [
      for (final p in contest.participants)
        if (p.retired)
          RetirementDraft(
            sourcePilotNo: p.sourcePilotNo,
            retiredAtRound: (lastScored[p.sourcePilotNo] ?? 0) + 1,
          ),
    ]..sort((a, b) => a.sourcePilotNo.compareTo(b.sourcePilotNo));
    for (final r in retirements) {
      warnings.add(
        RestoreWarning(
          RestoreWarning.retirementInferred,
          round: r.retiredAtRound,
          sourcePilotNo: r.sourcePilotNo,
        ),
      );
    }
    final retiredAt = {
      for (final r in retirements) r.sourcePilotNo: r.retiredAtRound,
    };

    // Rounds flown, partly flown and not flown.
    final lastFlown = scored.map((f) => f.roundNo).fold<int>(0, math.max);
    final partly = <int>{};
    for (final f in draw.flights) {
      if (f.scored || f.roundNo > lastFlown) {
        continue;
      }
      final retired = retiredAt[f.sourcePilotNo];
      if (retired != null && retired <= f.roundNo) {
        continue;
      }
      partly.add(f.roundNo);
    }
    final partlyFlown = partly.toList()..sort();
    for (final r in partlyFlown) {
      warnings.add(RestoreWarning(RestoreWarning.roundPartlyFlown, round: r));
    }
    if (scored.isEmpty) {
      warnings.add(const RestoreWarning(RestoreWarning.noScoredFlights));
    }

    final plan = RestorePlan(
      sourceCompNo: contest.sourceCompNo,
      identity: identity,
      status: RestoreStatus.importable,
      contest: contest,
      draw: draw,
      flights: flights,
      reflights: reflights,
      retirements: retirements,
      landing: landing,
      partlyFlownRounds: partlyFlown,
      trailingUnflownRounds: draw.probablyUnflownRounds,
      completedByDefault: scored.isNotEmpty && partlyFlown.isEmpty,
      warnings: warnings,
    );
    return RestorePlan(
      sourceCompNo: plan.sourceCompNo,
      identity: plan.identity,
      status: plan.status,
      contest: plan.contest,
      draw: plan.draw,
      flights: plan.flights,
      reflights: plan.reflights,
      retirements: plan.retirements,
      landing: plan.landing,
      partlyFlownRounds: plan.partlyFlownRounds,
      trailingUnflownRounds: plan.trailingUnflownRounds,
      completedByDefault: plan.completedByDefault,
      warnings: plan.warnings,
      contentHash: contentHashOf(plan),
    );
  }

  /// The hash of what [plan] restores: the same for the same content, from
  /// whichever copy of the file, and independent of warnings.
  static String contentHashOf(RestorePlan plan) =>
      stableHash(canonicalContent(plan));

  /// The canonical text [contentHashOf] hashes.
  static String canonicalContent(RestorePlan plan) {
    final c = plan.contest;
    final d = plan.draw;
    final content = <String, Object?>{
      'identity': plan.identity.key,
      'contest': {
        'name': c.name,
        'host': c.host,
        'start': c.startDate?.toIso8601String(),
        'discipline': c.disciplineType,
        'config': c.config?.toJson(),
        'source_landing_table': c.sourceLandingTableNo,
        'source_lane_count': c.sourceLaneCount,
        'participants': [
          for (final p in [
            ...c.participants,
          ]..sort((a, b) => a.sourcePilotNo.compareTo(b.sourcePilotNo)))
            [
              p.sourcePilotNo,
              p.role.name,
              p.sourceRole,
              p.retired,
              p.participantNumber,
              p.classification,
              p.sourceTeamNo,
              p.modelName,
              p.modelId,
            ],
        ],
        'teams': [
          for (final t in c.teams) [t.sourceTeamNo, t.name],
        ],
      },
      if (d != null)
        'draw': {
          'lanes': d.laneCount,
          'team_protection': d.teamProtection,
          'revisions': [
            for (final r in d.revisions)
              [
                r.taskNo,
                r.firstRound,
                r.lastRound,
                r.groupsPerRound,
                [
                  for (final round in r.rounds)
                    [
                      round.ordinal,
                      [
                        for (final g in round.groups)
                          [
                            g.groupNo,
                            [
                              for (final a in g.assignments)
                                [a.sourcePilotNo, a.seqNo, a.position, a.lane],
                            ],
                          ],
                      ],
                    ],
                ],
              ],
          ],
        },
      'flights': [
        for (final f in plan.flights)
          [
            f.key,
            f.groupNo,
            f.kind.name,
            _sorted(f.components),
            _sorted(f.rawComponents),
          ],
      ],
      'reflights': [
        for (final r in plan.reflights)
          [
            r.taskNo,
            r.roundNo,
            r.reflightNo,
            r.sourceGroupNo,
            r.flownGroupNo,
            [
              for (final m in r.members)
                [m.sourcePilotNo, m.role.name, m.position, m.scored],
            ],
          ],
      ],
      'retirements': [
        for (final r in plan.retirements) [r.sourcePilotNo, r.retiredAtRound],
      ],
      if (plan.landing != null)
        'landing': {
          'match': plan.landing!.match.name,
          'system': plan.landing!.systemTable,
          'name': plan.landing!.reconstructedName,
          'entries': [
            for (final e in plan.landing!.entries)
              [e.entryKey, e.label, e.points],
          ],
          'keys': _sorted({
            for (final e in plan.landing!.entryKeys.entries)
              '${e.key}': e.value,
          }),
        },
      'trailing': plan.trailingUnflownRounds,
    };
    return jsonEncode(content);
  }

  static Map<String, Object?> _sorted(Map<String, Object?> map) => {
    for (final k in map.keys.toList()..sort()) k: map[k],
  };

  static String? _dateKey(DateTime? date) => date == null
      ? null
      : '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';

  static GliderScoreTable? _table(GliderScoreImportResult r, String name) {
    for (final table in r.tables) {
      if (table.name.toLowerCase() == name.toLowerCase()) {
        return table;
      }
    }
    return null;
  }

  static Map<String, Object?>? _row(
    GliderScoreImportResult r,
    String table,
    int compNo,
  ) {
    for (final row
        in _table(r, table)?.rows ?? const <Map<String, Object?>>[]) {
      if (GliderScoreContestMapper.number(row['CompNo'])?.toInt() == compNo) {
        return row;
      }
    }
    return null;
  }

  static List<({int value, num points})> _landingRows(
    GliderScoreImportResult r,
    int? tableNo,
  ) {
    if (tableNo == null) {
      return const [];
    }
    final out = <({int value, num points})>[];
    for (final row in _table(r, 'LndgPoints')?.rows ?? const []) {
      if (GliderScoreContestMapper.number(row['LndgNo'])?.toInt() != tableNo) {
        continue;
      }
      final value = GliderScoreContestMapper.number(row['Distance']);
      final points = GliderScoreContestMapper.number(row['Points']);
      if (value != null && points != null) {
        out.add((value: value.toInt(), points: points));
      }
    }
    out.sort((a, b) => a.value.compareTo(b.value));
    return out;
  }

  static String? _landingName(GliderScoreImportResult r, int? tableNo) {
    if (tableNo == null) {
      return null;
    }
    for (final row in _table(r, 'LndgNames')?.rows ?? const []) {
      if (GliderScoreContestMapper.number(row['LndgNo'])?.toInt() == tableNo) {
        return GliderScoreContestMapper.text(row['Name']);
      }
    }
    return null;
  }
}
