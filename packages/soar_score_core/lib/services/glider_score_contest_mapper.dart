import '../enums/draw_mode.dart';
import '../enums/group_score_mode.dart';
import '../enums/lane_mode.dart';
import '../enums/rounding_mode.dart';
import '../models/contest/contest_config.dart';
import '../models/imports/contest_import_draft.dart';
import '../models/imports/glider_score_import_result.dart';
import '../models/imports/pilot_import_draft.dart';
import 'glider_score_pilot_mapper.dart';

/// The class-specific part of the competition mapping.
///
/// The mapper core knows nothing about F5J: it reads the competition,
/// participants and core options, and asks the class mapper of the
/// competition's `GSCompClass` for the discipline settings. A new class is a
/// new [ClassMapper] in the registry, not a change to the core.
abstract class ClassMapper {
  const ClassMapper();

  /// The GliderScore `GSCompClass` this mapper reads.
  String get sourceClass;

  /// The Soar Score discipline type, for example `F5J`.
  String get disciplineType;

  /// The discipline settings of the first configuration revision, from the
  /// class configuration row (`Dur` for F5J).
  DisciplineMapping mapDiscipline(Map<String, Object?> configRow);
}

/// What a [ClassMapper] read from a class configuration row.
class DisciplineMapping {
  DisciplineMapping({
    required this.settings,
    this.defaulted = const [],
    this.warnings = const [],
    this.sourceLandingTableNo,
  });

  /// The `discipline` part of the configuration, with the profile's field
  /// keys.
  final Map<String, Object?> settings;

  /// Profile field keys left at the profile default for lack of a value.
  final List<String> defaulted;

  final List<ContestImportWarning> warnings;

  /// The source landing table number when it is not the default.
  final int? sourceLandingTableNo;
}

/// F5J: the `Dur` row. Mapping plan section 5.2.
class F5jClassMapper extends ClassMapper {
  const F5jClassMapper();

  @override
  String get sourceClass => 'F5J';

  @override
  String get disciplineType => 'F5J';

  @override
  DisciplineMapping mapDiscipline(Map<String, Object?> row) {
    final settings = <String, Object?>{};
    final defaulted = <String>[];
    final warnings = <ContestImportWarning>[];

    void integer(String column, String key, {int min = 0, int? max}) {
      final value = GliderScoreContestMapper.number(row[column]);
      if (value == null) {
        defaulted.add(key);
        return;
      }
      final rounded = value.round();
      if (rounded < min || (max != null && rounded > max)) {
        warnings.add(
          ContestImportWarning(
            ContestImportWarning.settingOutOfRange,
            detail: '$key=$value',
          ),
        );
        defaulted.add(key);
        return;
      }
      if (rounded != value) {
        warnings.add(
          ContestImportWarning(
            ContestImportWarning.settingRounded,
            detail: '$key=$value',
          ),
        );
      }
      settings[key] = rounded;
    }

    void decimal(String column, String key) {
      final value = GliderScoreContestMapper.number(row[column]);
      if (value == null || value < 0) {
        defaulted.add(key);
        return;
      }
      settings[key] = value.toDouble();
    }

    integer('durTargetTime', 'working_time', min: 1);
    decimal('DurPointsPerSecond', 'points_per_second');
    integer('durDecimalsForTiming', 'fractional_seconds', max: 3);
    integer('durRefHeight', 'reference_launch_height', min: 1);
    decimal('durPenaltyUpToRefHeight', 'minor_penalty_per_meter');
    decimal('durPenaltyOverRefHeight', 'major_penalty_per_meter');

    // 0/1/2 = not allowed / allowed, zero cannot be dropped / allowed, zero
    // can be dropped. Empty in files that predate the setting: a restart
    // flag never zeroed the flight there, so the profile default stays.
    final restart = GliderScoreContestMapper.number(
      row['F5JMotorRestartOption'],
    );
    switch (restart?.toInt()) {
      case 0:
        settings['motor_restart_mode'] = 'not_allowed';
      case 1:
        settings['motor_restart_mode'] = 'non_droppable';
      case 2:
        settings['motor_restart_mode'] = 'allowed';
      case null:
        defaulted.add('motor_restart_mode');
        warnings.add(
          const ContestImportWarning(ContestImportWarning.motorRestartUnset),
        );
      default:
        defaulted.add('motor_restart_mode');
        warnings.add(
          ContestImportWarning(
            ContestImportWarning.settingOutOfRange,
            detail: 'motor_restart_mode=$restart',
          ),
        );
    }

    final landing = GliderScoreContestMapper.number(row['durLndg'])?.toInt();
    if (landing != null && landing != 0) {
      warnings.add(
        ContestImportWarning(
          ContestImportWarning.landingTableNotImported,
          detail: '$landing',
        ),
      );
    }
    defaulted.add('landing_table');

    return DisciplineMapping(
      settings: settings,
      defaulted: defaulted,
      warnings: warnings,
      sourceLandingTableNo: landing != null && landing != 0 ? landing : null,
    );
  }
}

/// Turns the competitions of a [GliderScoreImportResult] into a
/// [CompetitionImportDraft] for the director to review.
///
/// Pure: no I/O, never throws on odd input. Every column except the numbers,
/// the name and the class is optional, because GliderScore versions differ
/// and the exporter leaves null columns out of a row altogether. Mapping
/// rules: `plan/research/gliderscore-mdb-import/mapping-plan.md` sections
/// 5.1, 5.2 and 5.4. Draw, flights and scores are not mapped.
class GliderScoreContestMapper {
  const GliderScoreContestMapper({
    this.classMappers = const {'F5J': F5jClassMapper()},
    this.pilotMapper = const GliderScorePilotMapper(),
  });

  /// The registered classes, by `GSCompClass`. Any other class is skipped
  /// with the reason in [skippedClasses].
  final Map<String, ClassMapper> classMappers;

  final GliderScorePilotMapper pilotMapper;

  /// The GliderScore versions the mapping was checked against.
  static const testedVersions = {'6.78'};

  /// Why each class that is not registered is not imported. A class missing
  /// from this table is [ContestImportReason.classUnknown].
  static const skippedClasses = <String, String>{
    'F3J': ContestImportReason.classNotSupportedYet,
    'DurGeneral': ContestImportReason.classNotSupportedYet,
    'DurALES': ContestImportReason.classNotSupportedYet,
    'F3B': ContestImportReason.classOutOfScope,
    'F3K': ContestImportReason.classOutOfScope,
    'F3L': ContestImportReason.classOutOfScope,
    'F5B': ContestImportReason.classOutOfScope,
    'F5L': ContestImportReason.classOutOfScope,
    'Spd': ContestImportReason.classOutOfScope,
    'Elec': ContestImportReason.classOutOfScope,
  };

  /// Soar Score allows at most this many drops.
  static const maxDrops = 2;

  CompetitionImportDraft map(GliderScoreImportResult result) {
    final pilots = pilotMapper.map(result);
    final warnings = <ContestImportWarning>[];

    final version = _version(result);
    if (version == null || !testedVersions.contains(version)) {
      warnings.add(
        ContestImportWarning(
          ContestImportWarning.dbVersionUntested,
          detail: version,
        ),
      );
    }

    final comps = _table(result, 'Comps');
    if (comps == null) {
      return CompetitionImportDraft(
        sourceDbFile: result.sourceDbFile,
        sourceVersion: version,
        contests: const [],
        pilots: pilots,
        warnings: [
          ...warnings,
          const ContestImportWarning(ContestImportWarning.compsTableMissing),
        ],
      );
    }
    for (final name in ['Comps', 'CompPilots', 'Dur']) {
      final t = _table(result, name);
      if (t != null && t.rowCapExceeded) {
        warnings.add(
          ContestImportWarning(
            ContestImportWarning.rowsTruncated,
            detail: '$name ${t.rows.length} of ${t.rowCount}',
          ),
        );
      }
    }

    final configRows = <int, Map<String, Object?>>{};
    for (final row in _table(result, 'Dur')?.rows ?? const []) {
      final no = number(row['CompNo'])?.toInt();
      if (no != null) {
        configRows.putIfAbsent(no, () => row);
      }
    }
    final memberRows = <int, List<Map<String, Object?>>>{};
    for (final row in _table(result, 'CompPilots')?.rows ?? const []) {
      final no = number(row['CompNo'])?.toInt();
      if (no != null) {
        memberRows.putIfAbsent(no, () => []).add(row);
      }
    }

    final pilotsByNo = {
      for (final p in pilots.pilots)
        if (p.sourcePilotNo != null) p.sourcePilotNo!: p,
    };
    final unusablePilots = {
      for (final s in pilots.skipped)
        if (s.sourcePilotNo != null) s.sourcePilotNo!,
    };

    final contests = <ContestImportDraft>[];
    final seen = <int>{};
    for (final row in comps.rows) {
      final no = number(row['CompNo'])?.toInt();
      if (no == null) {
        warnings.add(
          const ContestImportWarning(ContestImportWarning.compNumberMissing),
        );
        continue;
      }
      if (!seen.add(no)) {
        warnings.add(
          ContestImportWarning(
            ContestImportWarning.duplicateCompNumber,
            detail: '$no',
          ),
        );
        continue;
      }
      contests.add(
        _mapCompetition(
          no,
          row,
          configRows[no],
          memberRows[no] ?? const [],
          pilotsByNo,
          unusablePilots,
          pilots.excludedPilotNumbers,
        ),
      );
    }
    contests.sort((a, b) => a.sourceCompNo.compareTo(b.sourceCompNo));

    return CompetitionImportDraft(
      sourceDbFile: result.sourceDbFile,
      sourceVersion: version,
      contests: contests,
      pilots: pilots,
      warnings: warnings,
    );
  }

  ContestImportDraft _mapCompetition(
    int no,
    Map<String, Object?> row,
    Map<String, Object?>? configRow,
    List<Map<String, Object?>> members,
    Map<int, PilotDraft> pilotsByNo,
    Set<int> unusablePilots,
    Set<int> testPilots,
  ) {
    final sourceClass = text(row['GSCompClass']) ?? '';
    final warnings = <ContestImportWarning>[];

    final rawName = text(row['CompName']);
    if (rawName == null) {
      warnings.add(
        const ContestImportWarning(ContestImportWarning.nameMissing),
      );
    }
    final name = rawName ?? 'GliderScore competition $no';
    final host = text(row['CompVenue']);
    final startDate = parseDate(row['CompDate']);

    ContestImportDraft refused(
      String status,
      String reason, [
      String? detail,
    ]) => ContestImportDraft(
      sourceCompNo: no,
      sourceClass: sourceClass,
      status: status == 'skipped'
          ? ContestImportStatus.skipped
          : ContestImportStatus.blocked,
      reason: reason,
      reasonDetail: detail,
      name: name,
      host: host,
      startDate: startDate,
      warnings: warnings,
    );

    final classMapper = classMappers[sourceClass];
    if (classMapper == null) {
      return refused(
        'skipped',
        skippedClasses[sourceClass] ?? ContestImportReason.classUnknown,
        sourceClass.isEmpty ? null : sourceClass,
      );
    }
    if (configRow == null) {
      return refused('blocked', ContestImportReason.configMissing);
    }
    if (startDate == null) {
      return refused(
        'blocked',
        ContestImportReason.dateMissing,
        text(row['CompDate']),
      );
    }

    final prelim = number(row['PrelimCompNo'])?.toInt();
    if (prelim != null && prelim > 0) {
      warnings.add(
        ContestImportWarning(
          ContestImportWarning.prelimNotImported,
          detail: '$prelim',
        ),
      );
    }
    if (flag(row['ScoresLocked'])) {
      warnings.add(
        const ContestImportWarning(
          ContestImportWarning.scoresLockedNotImported,
        ),
      );
    }

    final defaulted = <String>[];
    final core = <String, Object?>{};
    void put(String column, String key, Object? Function(Object? v) read) {
      final value = row[column] == null ? null : read(row[column]);
      if (value == null) {
        defaulted.add('core.$key');
      } else {
        core[key] = value;
      }
    }

    put('GroupScoreOption', 'group_score_mode', (v) {
      switch (number(v)?.toInt()) {
        case 1:
          return GroupScoreMode.normalized.json;
        case 2:
          return GroupScoreMode.time.json;
      }
      warnings.add(
        ContestImportWarning(
          ContestImportWarning.settingOutOfRange,
          detail: 'GroupScoreOption=$v',
        ),
      );
      return null;
    });
    put('RoundOrTruncate', 'rounding_mode', (v) {
      switch (number(v)?.toInt()) {
        case 0:
          return RoundingMode.round.json;
        case 1:
          return RoundingMode.truncate.json;
      }
      warnings.add(
        ContestImportWarning(
          ContestImportWarning.settingOutOfRange,
          detail: 'RoundOrTruncate=$v',
        ),
      );
      return null;
    });
    put('GroupScoreDecimals', 'decimal_places', (v) {
      final places = number(v)?.toInt();
      if (places != null && places >= 0 && places <= 3) {
        return places;
      }
      warnings.add(
        ContestImportWarning(
          ContestImportWarning.settingOutOfRange,
          detail: 'GroupScoreDecimals=$v',
        ),
      );
      return null;
    });
    put('DrawMode', 'draw_mode', (v) {
      if (number(v)?.toInt() == 0) {
        return DrawMode.standardManOnMan.json;
      }
      warnings.add(
        ContestImportWarning(
          ContestImportWarning.settingOutOfRange,
          detail: 'DrawMode=$v',
        ),
      );
      return null;
    });

    final drops = _drops(row, warnings);
    if (drops == null) {
      defaulted.add('core.drop_after_rounds');
    } else {
      core['drop_after_rounds'] = drops;
    }

    final teamsEnabled = flag(row['UseTeams']);
    core['teams_enabled'] = teamsEnabled;
    if (teamsEnabled) {
      var count = number(row['NbrForTeamScore'])?.toInt();
      if (count == null || count < 1) {
        warnings.add(
          ContestImportWarning(
            ContestImportWarning.teamPilotCountDefaulted,
            detail: '${row['NbrForTeamScore']}',
          ),
        );
        count = 1;
      }
      core['team_pilot_count'] = count;
      core['team_protection'] = flag(row['UseTeamProtection']);
    }
    final rolesEnabled = flag(row['UseRoles']);
    final classesEnabled = flag(row['UseClasses']);
    final modelsEnabled = flag(row['UseModels']);
    final numbering = flag(row['UsePilotNumbering']);
    core['roles_enabled'] = rolesEnabled;
    core['classes_enabled'] = classesEnabled;
    core['models_enabled'] = modelsEnabled;
    core['participant_numbers_enabled'] = numbering;

    final discipline = classMapper.mapDiscipline(configRow);
    warnings.addAll(discipline.warnings);
    for (final k in discipline.defaulted) {
      defaulted.add('discipline.$k');
    }

    final lanes = number(configRow['durNbrOfLanes'])?.toInt() ?? 0;
    core['lane_mode'] = lanes > 0 ? LaneMode.random.json : LaneMode.none.json;
    if (lanes > 0) {
      warnings.add(
        ContestImportWarning(
          ContestImportWarning.lanesCountKept,
          detail: '$lanes',
        ),
      );
    }

    final config = ContestConfig(core: core, discipline: discipline.settings);
    try {
      config.coreOptions;
    } on ArgumentError catch (e) {
      return refused(
        'blocked',
        ContestImportReason.configInvalid,
        '${e.message}',
      );
    }

    final people = _participants(
      members: members,
      teamsEnabled: teamsEnabled,
      rolesEnabled: rolesEnabled,
      classesEnabled: classesEnabled,
      modelsEnabled: modelsEnabled,
      numbering: numbering,
      pilotsByNo: pilotsByNo,
      unusablePilots: unusablePilots,
      testPilots: testPilots,
      warnings: warnings,
    );
    if (people.participants.isEmpty) {
      return refused(
        'blocked',
        ContestImportReason.noParticipants,
        'rows=${members.length} skipped=${people.skipped.length} '
            'test=${people.testPilots}',
      );
    }

    return ContestImportDraft(
      sourceCompNo: no,
      sourceClass: sourceClass,
      status: ContestImportStatus.importable,
      name: name,
      host: host,
      startDate: startDate,
      disciplineType: classMapper.disciplineType,
      config: config,
      defaultedSettings: defaulted,
      sourceLandingTableNo: discipline.sourceLandingTableNo,
      sourceLaneCount: lanes > 0 ? lanes : null,
      participants: people.participants,
      skippedParticipants: people.skipped,
      teams: people.teams,
      excludedTestUsers: people.testPilots,
      warnings: warnings,
    );
  }

  /// The drop settings, lowest rounds first, at most [maxDrops]; null when
  /// the file has no drop column at all.
  List<int>? _drops(
    Map<String, Object?> row,
    List<ContestImportWarning> warnings,
  ) {
    var anyColumn = false;
    final rounds = <int>{};
    for (var i = 1; i <= 5; i++) {
      final raw = row['Drop${i}AtRound'];
      if (raw == null) {
        continue;
      }
      anyColumn = true;
      final round = number(raw)?.toInt();
      if (round == null || round < 1) {
        warnings.add(
          ContestImportWarning(
            ContestImportWarning.dropInvalid,
            detail: 'Drop${i}AtRound=$raw',
          ),
        );
      } else if (round < 99) {
        rounds.add(round);
      }
    }
    if (!anyColumn) {
      return null;
    }
    final sorted = rounds.toList()..sort();
    if (sorted.length > maxDrops) {
      warnings.add(
        ContestImportWarning(
          ContestImportWarning.dropsDiscarded,
          detail:
              'kept ${sorted.take(maxDrops).join(',')}; '
              'discarded ${sorted.skip(maxDrops).join(',')}',
        ),
      );
    }
    return sorted.take(maxDrops).toList();
  }

  _People _participants({
    required List<Map<String, Object?>> members,
    required bool teamsEnabled,
    required bool rolesEnabled,
    required bool classesEnabled,
    required bool modelsEnabled,
    required bool numbering,
    required Map<int, PilotDraft> pilotsByNo,
    required Set<int> unusablePilots,
    required Set<int> testPilots,
    required List<ContestImportWarning> warnings,
  }) {
    final skipped = <SkippedParticipation>[];
    final built = <_Member>[];
    final seen = <int>{};
    var testCount = 0;
    var teamIgnored = false;
    var modelsDropped = false;
    var classesDropped = false;
    var rolesOffWithRoles = false;

    for (final row in members) {
      final pilotNo = number(row['PilotNo'])?.toInt();
      if (pilotNo == null) {
        skipped.add(
          const SkippedParticipation(
            sourcePilotNo: null,
            reason: ContestImportWarning.participantPilotMissing,
          ),
        );
        continue;
      }
      if (testPilots.contains(pilotNo)) {
        testCount++;
        continue;
      }
      if (!pilotsByNo.containsKey(pilotNo)) {
        skipped.add(
          SkippedParticipation(
            sourcePilotNo: pilotNo,
            reason: unusablePilots.contains(pilotNo)
                ? ContestImportWarning.participantPilotUnusable
                : ContestImportWarning.participantPilotMissing,
          ),
        );
        continue;
      }
      if (!seen.add(pilotNo)) {
        skipped.add(
          SkippedParticipation(
            sourcePilotNo: pilotNo,
            reason: ContestImportWarning.duplicateParticipation,
          ),
        );
        continue;
      }

      final sourceRole = text(row['Role']) ?? 'Plt';
      final role = _role(sourceRole, row, pilotNo, warnings);
      if (sourceRole.toLowerCase() != 'plt' && !rolesEnabled) {
        rolesOffWithRoles = true;
      }

      final retired = flag(row['Retired']);
      if (retired) {
        warnings.add(
          ContestImportWarning(
            ContestImportWarning.retiredKeptActive,
            sourcePilotNo: pilotNo,
          ),
        );
      }
      if (flag(row['OmitFromTeamScore'])) {
        warnings.add(
          ContestImportWarning(
            ContestImportWarning.omitFromTeamScoreDropped,
            sourcePilotNo: pilotNo,
          ),
        );
      }

      var team = number(row['Team'])?.toInt();
      if (team != null && team <= 0) {
        team = null;
      }
      if (team != null && !teamsEnabled) {
        teamIgnored = true;
        team = null;
      }

      String? classification;
      final rawClass = text(row['PilotClass']);
      if (role.flies && rawClass != null) {
        if (classesEnabled) {
          classification = rawClass;
        } else {
          classesDropped = true;
        }
      }

      String? modelName;
      String? modelId;
      final rawModel = text(row['Model']);
      if (role.flies && rawModel != null) {
        if (modelsEnabled) {
          modelName = rawModel;
          final data = text(row['ModelData']);
          modelId = data == null || data == '-1' ? null : data;
        } else {
          modelsDropped = true;
        }
      }

      built.add(
        _Member(
          ParticipationDraft(
            sourcePilotNo: pilotNo,
            role: role,
            sourceRole: sourceRole,
            retired: retired,
            sourceTeamNo: team,
            classification: classification,
            modelName: modelName,
            modelId: modelId,
          ),
          number(row['StartNo'])?.toInt() ?? 0,
        ),
      );
    }

    if (teamIgnored) {
      warnings.add(
        const ContestImportWarning(ContestImportWarning.teamIgnored),
      );
    }
    if (modelsDropped) {
      warnings.add(
        const ContestImportWarning(ContestImportWarning.modelsDisabledDropped),
      );
    }
    if (classesDropped) {
      warnings.add(
        const ContestImportWarning(ContestImportWarning.classesDisabledDropped),
      );
    }
    if (rolesOffWithRoles) {
      warnings.add(
        const ContestImportWarning(ContestImportWarning.rolesPresentFlagOff),
      );
    }

    final numbers = numbering ? _numbers(built, warnings) : const <int, int>{};
    final participants = [
      for (final m in built)
        ParticipationDraft(
          sourcePilotNo: m.draft.sourcePilotNo,
          role: m.draft.role,
          sourceRole: m.draft.sourceRole,
          retired: m.draft.retired,
          participantNumber: numbers[m.draft.sourcePilotNo],
          classification: m.draft.classification,
          sourceTeamNo: m.draft.sourceTeamNo,
          modelName: m.draft.modelName,
          modelId: m.draft.modelId,
        ),
    ];

    final teamNumbers = {
      for (final p in participants)
        if (p.sourceTeamNo != null) p.sourceTeamNo!,
    }.toList()..sort();
    if (teamNumbers.isNotEmpty) {
      warnings.add(
        ContestImportWarning(
          ContestImportWarning.teamNamesGenerated,
          detail: '${teamNumbers.length}',
        ),
      );
    }

    return _People(participants, skipped, [
      for (final t in teamNumbers) TeamDraft(sourceTeamNo: t, name: 'Team $t'),
    ], testCount);
  }

  /// Participant numbers for the fliers: a positive `StartNo` is kept the
  /// first time it is used (in `StartNo`, `PilotNo` order); the rest take the
  /// smallest free numbers in `PilotNo` order, so the numbers stay distinct.
  Map<int, int> _numbers(
    List<_Member> members,
    List<ContestImportWarning> warnings,
  ) {
    final fliers = [
      for (final m in members)
        if (m.draft.role.flies) m,
    ];
    final byStart = [...fliers]
      ..sort((a, b) {
        final c = a.startNo.compareTo(b.startNo);
        return c != 0
            ? c
            : a.draft.sourcePilotNo.compareTo(b.draft.sourcePilotNo);
      });
    final result = <int, int>{};
    final used = <int>{};
    final unnumbered = <_Member>[];
    for (final m in byStart) {
      if (m.startNo > 0 && used.add(m.startNo)) {
        result[m.draft.sourcePilotNo] = m.startNo;
      } else {
        if (m.startNo > 0) {
          warnings.add(
            ContestImportWarning(
              ContestImportWarning.startNumberDuplicate,
              sourcePilotNo: m.draft.sourcePilotNo,
              detail: '${m.startNo}',
            ),
          );
        }
        unnumbered.add(m);
      }
    }
    unnumbered.sort(
      (a, b) => a.draft.sourcePilotNo.compareTo(b.draft.sourcePilotNo),
    );
    var next = 1;
    for (final m in unnumbered) {
      while (used.contains(next)) {
        next++;
      }
      used.add(next);
      result[m.draft.sourcePilotNo] = next;
    }
    return result;
  }

  /// `IsPilot` decides whether the participant flies; the role code only
  /// chooses the role within that type (mapping plan 5.4).
  ImportedRole _role(
    String code,
    Map<String, Object?> row,
    int pilotNo,
    List<ContestImportWarning> warnings,
  ) {
    final isPilot = row['IsPilot'] == null ? null : flag(row['IsPilot']);
    ImportedRole base;
    switch (code.toLowerCase()) {
      case 'plt':
        base = ImportedRole.pilot;
      case 'hlp':
        base = ImportedRole.helper;
      case 'tm':
        base = ImportedRole.teamManager;
      case 'cd':
        base = ImportedRole.competitionDirector;
      case 'tm/plt' || 'cd/plt':
        base = ImportedRole.pilot;
        warnings.add(
          ContestImportWarning(
            ContestImportWarning.roleComposite,
            sourcePilotNo: pilotNo,
            detail: code,
          ),
        );
      default:
        warnings.add(
          ContestImportWarning(
            ContestImportWarning.roleUnknown,
            sourcePilotNo: pilotNo,
            detail: code,
          ),
        );
        return isPilot == false ? ImportedRole.helper : ImportedRole.pilot;
    }
    if (isPilot != null && isPilot != base.flies) {
      warnings.add(
        ContestImportWarning(
          ContestImportWarning.roleConflictIsPilot,
          sourcePilotNo: pilotNo,
          detail: code,
        ),
      );
      return isPilot ? ImportedRole.pilot : ImportedRole.helper;
    }
    return base;
  }

  static GliderScoreTable? _table(GliderScoreImportResult r, String name) {
    for (final table in r.tables) {
      if (table.name.toLowerCase() == name.toLowerCase()) {
        return table;
      }
    }
    return null;
  }

  static String? _version(GliderScoreImportResult r) {
    for (final row in _table(r, 'DBParams')?.rows ?? const []) {
      if (text(row['Property']) == 'DBVersion') {
        return text(row['PRValue']);
      }
    }
    return null;
  }

  /// [value] trimmed, or null when it is not text or is blank.
  static String? text(Object? value) {
    if (value == null) {
      return null;
    }
    final t = value.toString().trim();
    return t.isEmpty ? null : t;
  }

  static num? number(Object? value) {
    if (value is num) {
      return value;
    }
    return value is String ? num.tryParse(value.trim()) : null;
  }

  /// GliderScore's yes/no: `mdb-json` writes 0/1, other readers true/false.
  static bool flag(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final t = text(value)?.toLowerCase();
    return t == '1' || t == 'true' || t == 'yes';
  }

  /// A naive date from `MM/DD/YY[YY] HH:MM:SS` (as `mdb-json` writes it) or
  /// ISO `YYYY-MM-DD[ T]HH:MM:SS`, as UTC midnight of that calendar day;
  /// null when it is neither or not a real date.
  static DateTime? parseDate(Object? value) {
    final t = text(value);
    if (t == null) {
      return null;
    }
    int? y;
    int? m;
    int? d;
    final us = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2}|\d{4})(?:\s|T|$)')
        .firstMatch(t);
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:\s|T|$)').firstMatch(t);
    if (us != null) {
      m = int.parse(us.group(1)!);
      d = int.parse(us.group(2)!);
      y = int.parse(us.group(3)!);
      if (us.group(3)!.length == 2) {
        y += y < 70 ? 2000 : 1900;
      }
    } else if (iso != null) {
      y = int.parse(iso.group(1)!);
      m = int.parse(iso.group(2)!);
      d = int.parse(iso.group(3)!);
    } else {
      return null;
    }
    final date = DateTime.utc(y, m, d);
    return date.year == y && date.month == m && date.day == d ? date : null;
  }
}

class _Member {
  _Member(this.draft, this.startNo);

  final ParticipationDraft draft;
  final int startNo;
}

class _People {
  _People(this.participants, this.skipped, this.teams, this.testPilots);

  final List<ParticipationDraft> participants;
  final List<SkippedParticipation> skipped;
  final List<TeamDraft> teams;
  final int testPilots;
}
