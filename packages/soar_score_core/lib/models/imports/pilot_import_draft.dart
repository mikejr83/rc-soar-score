/// A pilot read from a GliderScore database, ready to review before anything
/// is stored. Carries the values of a `ParticipantProfile` without an owner,
/// id or timestamps: those are assigned when the director confirms.
class PilotDraft {
  const PilotDraft({
    required this.sourcePilotNo,
    required this.firstName,
    required this.lastName,
    this.email,
    this.faiNumber,
    this.nationalOrgId,
    this.club,
    this.city,
    this.state,
    this.country,
    this.warnings = const [],
  });

  /// GliderScore's `PilotNo`, the pilot's key in that file. Not stored.
  final int? sourcePilotNo;

  final String firstName;
  final String lastName;

  /// Trimmed, case kept; matching lower-cases it.
  final String? email;
  final String? faiNumber;
  final String? nationalOrgId;
  final String? club;
  final String? city;
  final String? state;

  /// The English country name, not GliderScore's code.
  final String? country;

  final List<PilotImportWarning> warnings;
}

/// Why a pilot was left out of the draft.
class SkippedPilot {
  const SkippedPilot({required this.sourcePilotNo, required this.reason});

  final int? sourcePilotNo;

  /// A stable code: [PilotImportWarning.missingName],
  /// [PilotImportWarning.missingNumber] or
  /// [PilotImportWarning.duplicatePilotNumber].
  final String reason;
}

/// Something the director should know about a pilot or the file.
class PilotImportWarning {
  const PilotImportWarning(this.code, {this.sourcePilotNo, this.detail});

  /// Neither a first nor a last name; the pilot is skipped.
  static const missingName = 'pilot_missing_name';

  /// The row has no usable `PilotNo`, so it cannot be traced or told apart
  /// from another; the pilot is skipped.
  static const missingNumber = 'pilot_missing_number';

  /// A second row with the same `PilotNo`; the later row is skipped.
  static const duplicatePilotNumber = 'duplicate_pilot_number';

  /// The country is not a GliderScore code or a known name; left blank.
  static const countryUnknown = 'country_unknown';

  /// The pilot has no country; left blank.
  static const countryMissing = 'country_missing';

  /// The email has no `@`; left blank.
  static const emailInvalid = 'email_invalid';

  /// `FAI_ID` and `FAINumber` both hold a value and differ; `FAINumber` wins.
  static const faiIdDiffers = 'fai_id_differs';

  /// The file has no `Pilots` table.
  static const pilotsTableMissing = 'pilots_table_missing';

  /// The `Pilots` table was larger than the import's row budget.
  static const rowsTruncated = 'rows_truncated';

  final String code;
  final int? sourcePilotNo;

  /// The raw value or a short note, for the review step.
  final String? detail;
}

/// The result of mapping a GliderScore database's `Pilots` table.
class PilotImportDraft {
  const PilotImportDraft({
    required this.pilots,
    required this.skipped,
    required this.excludedTestUsers,
    required this.droppedFieldCounts,
    required this.warnings,
    this.excludedPilotNumbers = const {},
  });

  /// Pilots to review, in file order.
  final List<PilotDraft> pilots;

  final List<SkippedPilot> skipped;

  /// Pilots left out because their last name starts with `ZZ`, which
  /// GliderScore uses for its bundled test pilots.
  final int excludedTestUsers;

  /// The `PilotNo` of each pilot counted in [excludedTestUsers], so a
  /// competition's participants can tell a test pilot from an unknown one.
  final Set<int> excludedPilotNumbers;

  /// For each GliderScore column with no profile field, how many included
  /// pilots had a value in it.
  final Map<String, int> droppedFieldCounts;

  /// File-level warnings; pilot warnings are on each [PilotDraft].
  final List<PilotImportWarning> warnings;
}
