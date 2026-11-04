import '../id.dart';
import 'contest_import_draft.dart';
import 'restore_plan.dart';

/// Who owns what an import writes.
///
/// The owner is the signed-in account, otherwise this installation's Local
/// account (ADR 0006). With neither, nothing can be written.
class ImportOwner {
  const ImportOwner({this.signedInAccountId, this.localAccountId});

  final Id? signedInAccountId;
  final Id? localAccountId;

  /// The account that owns the imported rows, or null when there is none.
  Id? get accountId => signedInAccountId ?? localAccountId;
}

/// One profile an import created or updated, to be stamped.
class ProfileStampEntry {
  const ProfileStampEntry({
    required this.sourcePilotNo,
    required this.profileId,
    required this.created,
  });

  /// GliderScore's `PilotNo`.
  final int sourcePilotNo;
  final Id profileId;

  /// True for a new profile, false for an updated one; only the audit note
  /// differs.
  final bool created;
}

/// The profiles one import operation created or updated, stamped before the
/// competitions are written (ADR 0006).
class ProfileStampPlan {
  const ProfileStampPlan({
    required this.owner,
    required this.importOperationId,
    required this.fileFingerprint,
    required this.toolVersion,
    required this.entries,
    this.sourceSystem = 'gliderscore',
  });

  final ImportOwner owner;
  final Id importOperationId;
  final String fileFingerprint;
  final String toolVersion;
  final String sourceSystem;
  final List<ProfileStampEntry> entries;
}

/// Everything needed to write one competition as a contest.
class CompetitionImportPlan {
  const CompetitionImportPlan({
    required this.draft,
    required this.profileIds,
    required this.owner,
    required this.timezone,
    required this.importOperationId,
    required this.fileFingerprint,
    required this.toolVersion,
    this.contestId,
  });

  /// The reviewed competition; it must be importable.
  final ContestImportDraft draft;

  /// The profile of each participant, by GliderScore `PilotNo`, from the
  /// pilot review. A participant whose pilot has no entry was left out by the
  /// director and is not written.
  final Map<int, Id> profileIds;

  final ImportOwner owner;

  /// The contest's IANA time zone: the importing installation's.
  final String timezone;

  /// One id per wizard run, shared by every row it writes.
  final Id importOperationId;

  /// Hash of the source file, the same for every competition of the run.
  final String fileFingerprint;

  final String toolVersion;

  /// The new contest's id; a retried plan passes the same one.
  final Id? contestId;
}

/// What happened to one competition.
sealed class CompetitionImportResult {
  const CompetitionImportResult(this.sourceCompNo);

  final int sourceCompNo;
}

/// The competition is now a contest.
class CompetitionImported extends CompetitionImportResult {
  const CompetitionImported(
    super.sourceCompNo, {
    required this.contestId,
    required this.participationCount,
    required this.skippedParticipants,
  });

  final Id contestId;
  final int participationCount;

  /// Participants left out because the director chose no profile for their
  /// pilot, by `PilotNo`.
  final List<int> skippedParticipants;
}

/// The same competition of the same file was imported before, and nothing
/// was written.
class CompetitionAlreadyImported extends CompetitionImportResult {
  const CompetitionAlreadyImported(
    super.sourceCompNo, {
    required this.contestId,
    required this.importedAt,
    required this.importOperationId,
  });

  final Id? contestId;
  final DateTime importedAt;
  final Id importOperationId;
}

/// The competition could not be written; nothing of it is kept.
class CompetitionImportFailed extends CompetitionImportResult {
  const CompetitionImportFailed(super.sourceCompNo, this.code, [this.detail]);

  /// A [CompetitionImportFailure] code.
  final String code;
  final String? detail;
}

/// Stable codes of [CompetitionImportFailed].
abstract final class CompetitionImportFailure {
  /// Neither a signed-in nor a Local account exists (ADR 0006).
  static const noAccount = 'import_no_account';

  /// The draft is blocked or skipped, or has no configuration.
  static const notImportable = 'not_importable';

  /// No published discipline profile exists for the competition's class.
  static const profileUnavailable = 'profile_unavailable';

  /// The mapped configuration is not valid for the pinned profile.
  static const configInvalid = 'config_invalid';

  /// A participant's profile is not stored or belongs to another owner.
  static const profileMissing = 'participant_profile_missing';

  /// Anything else; the competition was rolled back.
  static const failed = 'import_failed';
}

/// Everything needed to restore one competition: create the contest, or
/// update it in place when the same competition was restored before (ADR
/// 0006, amendment 2).
class RestoreImportPlan {
  const RestoreImportPlan({
    required this.plan,
    required this.profileIds,
    required this.owner,
    required this.timezone,
    required this.importOperationId,
    required this.fileFingerprint,
    required this.toolVersion,
    required this.completed,
    this.contestId,
    this.updateContestId,
    this.confirmedReplace = false,
  });

  /// The mapped competition; it must be importable.
  final RestorePlan plan;

  /// The profile of each participant, by GliderScore `PilotNo`.
  final Map<int, Id> profileIds;

  final ImportOwner owner;

  /// The contest's IANA time zone: the importing installation's.
  final String timezone;

  /// One id per wizard run, shared by every row it writes.
  final Id importOperationId;

  /// Hash of the source file, kept on the stamps for provenance only.
  final String fileFingerprint;

  final String toolVersion;

  /// The director's "Completed" checkbox.
  final bool completed;

  /// The new contest's id; a retried plan passes the same one.
  final Id? contestId;

  /// The contest to update although the identity differs, chosen by the
  /// director when a competition without `CompID` has the same number as an
  /// earlier import but another name or date.
  final Id? updateContestId;

  /// The director confirmed what an update replaces.
  final bool confirmedReplace;
}

/// How the competition relates to contests restored before.
enum RestoreTargetKind {
  /// Nothing restored from this competition yet.
  none,

  /// The same competition (by identity) was restored: an import updates it.
  same,

  /// No `CompID`, and an earlier import has this competition number with
  /// another name or date: the director decides whether it is the same.
  numberMatch,
}

/// What an update would replace, counted from the contest as it is now.
class ContestChanges {
  const ContestChanges({
    this.scoresEntered = 0,
    this.participantsChanged = false,
    this.drawChanged = false,
    this.configurationChanged = false,
    this.restoredScores = 0,
  });

  /// Scores entered in Soar Score after the restore.
  final int scoresEntered;
  final bool participantsChanged;
  final bool drawChanged;
  final bool configurationChanged;

  /// The scores the earlier restore made.
  final int restoredScores;

  /// Something was done in Soar Score after the restore.
  bool get any =>
      scoresEntered > 0 ||
      participantsChanged ||
      drawChanged ||
      configurationChanged;
}

/// What the restore of one competition would meet, read before the
/// director confirms.
class RestoreTarget {
  const RestoreTarget({
    required this.kind,
    this.contestId,
    this.contestName,
    this.sourceName,
    this.sourceDate,
    this.importedAt,
    this.storedHash,
    this.storedCompleted,
    this.published = false,
    this.synced = false,
    this.changes = const ContestChanges(),
  });

  const RestoreTarget.none() : this(kind: RestoreTargetKind.none);

  final RestoreTargetKind kind;
  final Id? contestId;
  final String? contestName;

  /// The name and date of the competition as the earlier import saw them.
  final String? sourceName;
  final String? sourceDate;
  final DateTime? importedAt;

  /// The content hash of the earlier restore, and its "Completed" choice.
  final String? storedHash;
  final bool? storedCompleted;

  /// The contest's results are published: an update is refused.
  final bool published;

  /// The contest reached the server: an update is refused (the server cannot
  /// take the removal of scores).
  final bool synced;
  final ContestChanges changes;

  bool get exists => kind != RestoreTargetKind.none;

  /// An import with [hash] and [completed] would change nothing.
  bool isUnchanged(String hash, bool completed) =>
      kind == RestoreTargetKind.same &&
      storedHash == hash &&
      storedCompleted == completed &&
      !changes.any;
}

/// What happened to one competition.
sealed class RestoreImportResult {
  const RestoreImportResult(this.sourceCompNo);

  final int sourceCompNo;
}

/// The competition is now a contest (new, or updated in place).
class CompetitionRestored extends RestoreImportResult {
  const CompetitionRestored(
    super.sourceCompNo, {
    required this.contestId,
    required this.updated,
    required this.participationCount,
    required this.flightCount,
    required this.finalState,
    required this.skippedParticipants,
  });

  final Id contestId;

  /// The contest existed and was replaced in place.
  final bool updated;
  final int participationCount;
  final int flightCount;
  final RestoreFinalState finalState;
  final List<int> skippedParticipants;
}

/// The contest already holds exactly this content; nothing was written.
class CompetitionUnchanged extends RestoreImportResult {
  const CompetitionUnchanged(
    super.sourceCompNo, {
    required this.contestId,
    required this.importedAt,
  });

  final Id contestId;
  final DateTime? importedAt;
}

/// The restore was not done and nothing was written; [code] says why.
class CompetitionRefused extends RestoreImportResult {
  const CompetitionRefused(super.sourceCompNo, this.code, {this.contestId});

  /// A [RestoreRefusal] code.
  final String code;
  final Id? contestId;
}

/// One restored flight whose recalculated score differs from GliderScore's.
class RestoreMismatch {
  const RestoreMismatch({
    required this.roundNo,
    required this.groupNo,
    required this.sourcePilotNo,
    required this.reflightNo,
    this.expected,
    this.actual,
    this.error,
  });

  final int roundNo;
  final int groupNo;
  final int sourcePilotNo;
  final int reflightNo;

  /// GliderScore's `RawScore`.
  final num? expected;

  /// What Soar Score's calculator gives.
  final double? actual;

  /// Why the calculator gave nothing.
  final String? error;
}

/// The restore of one competition failed and was rolled back.
class CompetitionRestoreFailed extends RestoreImportResult {
  const CompetitionRestoreFailed(
    super.sourceCompNo,
    this.code, {
    this.detail,
    this.mismatches = const [],
    this.mismatchCount = 0,
  });

  /// A [RestoreFailure] code.
  final String code;
  final String? detail;

  /// The first flights that differ (round, group, pilot number).
  final List<RestoreMismatch> mismatches;

  /// How many flights differ in all.
  final int mismatchCount;
}

/// Stable codes of [CompetitionRefused].
abstract final class RestoreRefusal {
  /// The contest's results are published; un-publish first.
  static const resultsPublished = 'results_published';

  /// The contest reached the server; a replace is not available yet.
  static const contestSynced = 'contest_synced';

  /// Soar Score holds changes the update would replace and the director has
  /// not confirmed.
  static const needsConfirmation = 'needs_confirmation';

  /// The director chose a contest to update that is not an earlier restore of
  /// this kind.
  static const notRestorable = 'contest_not_restorable';
}

/// Stable codes of [CompetitionRestoreFailed].
abstract final class RestoreFailure {
  /// Neither a signed-in nor a Local account exists (ADR 0006).
  static const noAccount = 'import_no_account';

  /// The plan is refused or holds nothing to write.
  static const notImportable = 'not_importable';

  /// No published discipline profile exists for the competition's class.
  static const profileUnavailable = 'profile_unavailable';

  /// The mapped configuration is not valid for the pinned profile.
  static const configInvalid = 'config_invalid';

  /// A participant's profile is not stored or belongs to another owner.
  static const profileMissing = 'participant_profile_missing';

  /// A restored score differs from GliderScore's; the competition was rolled
  /// back.
  static const comparisonFailed = 'comparison_failed';

  /// Anything else; the competition was rolled back.
  static const failed = 'import_failed';
}
