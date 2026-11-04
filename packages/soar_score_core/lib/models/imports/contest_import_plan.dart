import '../id.dart';
import 'contest_import_draft.dart';
import 'draw_import_draft.dart';

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

/// Everything needed to add the draw of one competition to the contest phase
/// B made from it (ADR 0006 amendment).
class DrawImportPlan {
  const DrawImportPlan({
    required this.draft,
    required this.contestId,
    required this.owner,
    required this.importOperationId,
    required this.fileFingerprint,
    required this.toolVersion,
  });

  /// The reviewed draw; it must be importable.
  final DrawImportDraft draft;

  /// The contest phase B created, from [DrawImportTarget.contestId].
  final Id contestId;

  final ImportOwner owner;

  /// One id per wizard run, shared by every row it writes.
  final Id importOperationId;

  /// Hash of the source file; it must be the one on the contest's stamp.
  final String fileFingerprint;

  final String toolVersion;
}

/// What happened to the draw of one competition.
sealed class DrawImportResult {
  const DrawImportResult(this.sourceCompNo);

  final int sourceCompNo;
}

/// The contest now has the competition's draw and is `Ready`.
class DrawImported extends DrawImportResult {
  const DrawImported(
    super.sourceCompNo, {
    required this.contestId,
    required this.revisionCount,
    required this.roundCount,
    required this.assignmentCount,
  });

  final Id contestId;
  final int revisionCount;
  final int roundCount;
  final int assignmentCount;
}

/// The draw could not be written; nothing of it is kept.
class DrawImportFailed extends DrawImportResult {
  const DrawImportFailed(super.sourceCompNo, this.code, [this.detail]);

  /// A [DrawImportReason] code (the contest no longer fits) or a
  /// [DrawImportFailure] code.
  final String code;
  final String? detail;
}

/// Stable codes of [DrawImportFailed] that are not refusals of the draw.
abstract final class DrawImportFailure {
  /// Neither a signed-in nor a Local account exists (ADR 0006).
  static const noAccount = 'import_no_account';

  /// The draft is refused or holds nothing to write.
  static const notImportable = 'not_importable';

  /// A pilot of the draw has no participation in the contest.
  static const participationMissing = 'participation_missing';

  /// The contest has no saved configuration.
  static const notConfigured = 'not_configured';

  /// The contest is locked by its director.
  static const contestLocked = 'contest_locked';

  /// Anything else; the competition was rolled back.
  static const failed = 'import_failed';
}
