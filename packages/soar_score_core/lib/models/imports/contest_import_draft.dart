import '../contest/contest_config.dart';
import 'pilot_import_draft.dart';

/// Whether a competition can be imported as a contest.
enum ContestImportStatus {
  /// Everything needed is there; the director may choose it.
  importable,

  /// The class is supported but this competition cannot be imported as it
  /// is; [ContestImportDraft.reason] says why.
  blocked,

  /// The class is not imported by this version; [ContestImportDraft.reason]
  /// says why.
  skipped,
}

/// A role a participation has in the contest.
///
/// A neutral key, not a database id: persistence maps it to the system role
/// or creates the director-owned one.
enum ImportedRole {
  /// The system Pilot role (flies).
  pilot,

  /// The system Helper role.
  helper,

  /// The system Team Manager role.
  teamManager,

  /// A director-owned "Competition Director" non-flier role.
  competitionDirector;

  bool get flies => this == pilot;
}

/// A competition of a GliderScore database, ready to review before anything
/// is stored. Carries the values of a `Contest`, its first configuration
/// revision and its participations, without ids, owner or timestamps.
///
/// No draw, flights or scores: those belong to later phases.
class ContestImportDraft {
  const ContestImportDraft({
    required this.sourceCompNo,
    required this.sourceClass,
    required this.status,
    this.reason,
    this.reasonDetail,
    this.name,
    this.host,
    this.startDate,
    this.disciplineType,
    this.config,
    this.defaultedSettings = const [],
    this.sourceLandingTableNo,
    this.sourceLaneCount,
    this.participants = const [],
    this.skippedParticipants = const [],
    this.teams = const [],
    this.excludedTestUsers = 0,
    this.warnings = const [],
  });

  /// GliderScore's `CompNo`, the competition's key in that file.
  final int sourceCompNo;

  /// GliderScore's `GSCompClass`, as written (trimmed).
  final String sourceClass;

  final ContestImportStatus status;

  /// A stable code (see [ContestImportReason]) for a blocked or skipped
  /// competition; null when importable.
  final String? reason;

  /// The raw value or a short note behind [reason].
  final String? reasonDetail;

  final String? name;

  /// The venue, as one string.
  final String? host;

  /// The naive date of the competition as UTC midnight of that calendar day:
  /// GliderScore stores no zone, so persistence reads year, month and day and
  /// applies the importing installation's contest time zone.
  final DateTime? startDate;

  /// The Soar Score discipline type, for example `F5J`.
  final String? disciplineType;

  /// The first configuration revision's settings.
  final ContestConfig? config;

  /// Setting keys (`core.x`, `discipline.y`) left at the platform or profile
  /// default because the file had no value.
  final List<String> defaultedSettings;

  /// GliderScore's landing table number when it is not the default, kept
  /// only for review: landing tables are not imported in this phase.
  final int? sourceLandingTableNo;

  /// GliderScore's lane count when it is above 0. Soar Score has no lane
  /// count setting (`lane_mode` only), so persistence keeps the number as a
  /// source value (ADR 0006) for review and for the draw phase to check.
  final int? sourceLaneCount;

  final List<ParticipationDraft> participants;
  final List<SkippedParticipation> skippedParticipants;
  final List<TeamDraft> teams;

  /// Test pilots (`ZZ` last names) left out of this competition.
  final int excludedTestUsers;

  final List<ContestImportWarning> warnings;

  bool get isImportable => status == ContestImportStatus.importable;
}

/// Why a competition is blocked or skipped.
abstract final class ContestImportReason {
  /// A class Soar Score will support, but this version does not import.
  static const classNotSupportedYet = 'class_not_supported_yet';

  /// A class Soar Score does not plan to import (no equivalent discipline).
  static const classOutOfScope = 'class_out_of_scope';

  /// A class this version does not know.
  static const classUnknown = 'class_unknown';

  /// The class configuration row (`Dur`) is missing.
  static const configMissing = 'config_missing';

  /// The competition has no usable date.
  static const dateMissing = 'comp_date_missing';

  /// The mapped settings do not form a valid configuration.
  static const configInvalid = 'config_invalid';

  /// No participant of the competition can be imported, so the contest could
  /// not be drawn or scored.
  static const noParticipants = 'no_participants';
}

/// One participant of a competition.
class ParticipationDraft {
  const ParticipationDraft({
    required this.sourcePilotNo,
    required this.role,
    required this.sourceRole,
    this.retired = false,
    this.participantNumber,
    this.classification,
    this.sourceTeamNo,
    this.modelName,
    this.modelId,
  });

  /// GliderScore's `PilotNo`; the profile comes from the pilot review.
  final int sourcePilotNo;

  final ImportedRole role;

  /// The `Role` code as written, kept for review and provenance.
  final String sourceRole;

  /// Set in GliderScore. Persistence leaves the participant active (a
  /// retirement is bound to a round) and the review warns.
  final bool retired;

  /// Only when the competition numbers its participants.
  final int? participantNumber;

  /// Only when the competition uses classes and the participant flies.
  final String? classification;

  /// GliderScore's team number; see [ContestImportDraft.teams].
  final int? sourceTeamNo;

  /// The model's name, only for a flier in a competition that uses models.
  final String? modelName;

  /// `ModelData` when it is a real identifier (not `-1`/blank).
  final String? modelId;
}

class SkippedParticipation {
  const SkippedParticipation({
    required this.sourcePilotNo,
    required this.reason,
  });

  final int? sourcePilotNo;

  /// A [ContestImportWarning] code.
  final String reason;
}

class TeamDraft {
  const TeamDraft({required this.sourceTeamNo, required this.name});

  final int sourceTeamNo;

  /// Generated: GliderScore has no team names.
  final String name;
}

/// Something the director should know about a competition or a participant.
class ContestImportWarning {
  const ContestImportWarning(this.code, {this.sourcePilotNo, this.detail});

  /// The file's `DBVersion` is missing or not one the importer was tested on.
  static const dbVersionUntested = 'db_version_untested';

  /// The file has no `Comps` table.
  static const compsTableMissing = 'comps_table_missing';

  /// A table was larger than the import's row budget.
  static const rowsTruncated = 'rows_truncated';

  /// The competition has no name; a placeholder is used.
  static const nameMissing = 'comp_name_missing';

  /// A `Comps` row has no usable `CompNo`; ignored.
  static const compNumberMissing = 'comp_number_missing';

  /// Two `Comps` rows share a `CompNo`; the later row is ignored.
  static const duplicateCompNumber = 'duplicate_comp_number';

  /// `PrelimCompNo` points at another competition; not imported.
  static const prelimNotImported = 'prelim_comp_not_imported';

  /// The competition was locked in GliderScore; locks are not imported.
  static const scoresLockedNotImported = 'scores_locked_not_imported';

  /// More drop settings than Soar Score allows; the lowest two are kept.
  static const dropsDiscarded = 'drops_discarded';

  /// A drop setting is not a usable round number; ignored.
  static const dropInvalid = 'drop_invalid';

  /// `NbrForTeamScore` is not 1 or more while teams are on; 1 is used.
  static const teamPilotCountDefaulted = 'team_pilot_count_defaulted';

  /// Teams are generated as "Team N" because GliderScore has no team names.
  static const teamNamesGenerated = 'team_names_generated';

  /// Participants have a team number but the competition has teams off.
  static const teamIgnored = 'team_ignored_teams_disabled';

  /// `OmitFromTeamScore` is set; Soar Score has no per-pilot exclusion.
  static const omitFromTeamScoreDropped = 'omit_from_team_score_dropped';

  /// `Roles` hold something other than pilots but `UseRoles` is off.
  static const rolesPresentFlagOff = 'roles_present_flag_off';

  /// A composite role (`TM/Plt`, `CD/Plt`) cannot be one role; the participant
  /// is a Pilot.
  static const roleComposite = 'role_composite_degraded';

  /// A role code that is not in GliderScore's `Roles` list.
  static const roleUnknown = 'role_unknown';

  /// The participant is retired in GliderScore; stays active until a draw.
  static const retiredKeptActive = 'retired_pilot_kept_active';

  /// A start number is used twice; the later participant is renumbered.
  static const startNumberDuplicate = 'start_number_duplicate';

  /// Participants carry models but the competition has models off.
  static const modelsDisabledDropped = 'models_disabled_dropped';

  /// Participants carry classes but the competition has classes off.
  static const classesDisabledDropped = 'classes_disabled_dropped';

  /// The participant has no row in `Pilots`; skipped.
  static const participantPilotMissing = 'participant_pilot_missing';

  /// The participant's pilot row cannot be imported (no name or number);
  /// skipped.
  static const participantPilotUnusable = 'participant_pilot_unusable';

  /// The participant's pilot is a `ZZ` test pilot; skipped.
  static const participantTestPilot = 'participant_test_pilot';

  /// A second row for the same pilot in one competition; skipped.
  static const duplicateParticipation = 'duplicate_participation';

  /// A lane count is set; the contest gets `lane_mode: Random` and the count
  /// is kept as a source value, not as a setting.
  static const lanesCountKept = 'lanes_count_kept_as_source_value';

  /// `IsPilot` and the `Role` code disagree about whether the participant
  /// flies; `IsPilot` wins and the role follows it.
  static const roleConflictIsPilot = 'role_conflict_is_pilot';

  /// A non-default landing table was used; landing tables are not imported.
  static const landingTableNotImported = 'landing_table_not_imported';

  /// `F5JMotorRestartOption` is empty (an old file); the default stays.
  static const motorRestartUnset = 'motor_restart_unset';

  /// A setting had a value outside what Soar Score allows; the default stays.
  static const settingOutOfRange = 'setting_out_of_range';

  /// A whole-number setting had a fractional value; it is rounded. The
  /// detail names the setting.
  static const settingRounded = 'setting_rounded';

  final String code;
  final int? sourcePilotNo;

  /// The raw value or a short note, for the review step.
  final String? detail;
}

/// The result of mapping the competitions of a GliderScore database.
class CompetitionImportDraft {
  const CompetitionImportDraft({
    required this.sourceDbFile,
    required this.sourceVersion,
    required this.contests,
    required this.pilots,
    required this.warnings,
  });

  final String sourceDbFile;

  /// The file's `DBVersion`, when it has one.
  final String? sourceVersion;

  /// One per `Comps` row, in `CompNo` order.
  final List<ContestImportDraft> contests;

  /// The `Pilots` table as the pilot import reads it; the profiles of a
  /// competition's participants are the pilots with a matching number.
  final PilotImportDraft pilots;

  /// File-level warnings (a [ContestImportWarning] code each).
  final List<ContestImportWarning> warnings;

  /// The pilots used by the importable competitions among [compNos], in
  /// `PilotNo` order: the only profiles an import of those competitions
  /// touches.
  List<PilotDraft> pilotsUsedBy(Set<int> compNos) {
    final used = <int>{
      for (final c in contests)
        if (compNos.contains(c.sourceCompNo) && c.isImportable)
          for (final p in c.participants) p.sourcePilotNo,
    };
    return [
      for (final p in pilots.pilots)
        if (p.sourcePilotNo != null && used.contains(p.sourcePilotNo)) p,
    ]..sort((a, b) => a.sourcePilotNo!.compareTo(b.sourcePilotNo!));
  }
}
