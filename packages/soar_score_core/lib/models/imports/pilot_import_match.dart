import '../id.dart';
import 'pilot_import_draft.dart';

/// How a drafted pilot relates to the director's existing participants.
enum PilotMatchKind {
  /// No existing profile matches.
  newPilot,

  /// Exactly one existing profile has the same email, FAI number or national
  /// organization ID.
  exact,

  /// Only a name matches, or several profiles match a key, or an earlier
  /// pilot in the same file matches this one. A person has to decide.
  likely,
}

/// What a match is based on, strongest first.
enum PilotMatchRule { email, faiNumber, nationalOrgId, name }

/// What the review step starts with for a match.
enum PilotImportAction { add, update, ask }

/// A profile field the import would change on an existing profile.
class PilotFieldChange {
  const PilotFieldChange({
    required this.field,
    required this.from,
    required this.to,
  });

  /// `email`, `faiNumber`, `nationalOrgId`, `club`, `city`, `state` or
  /// `country`.
  final String field;
  final String? from;
  final String to;
}

/// One drafted pilot with the existing profiles it may be.
class PilotMatch {
  const PilotMatch({
    required this.draft,
    required this.kind,
    required this.candidateIds,
    this.candidateRevisions = const {},
    this.rule,
    this.conflict = false,
    this.changes = const [],
    this.duplicateOfSourcePilotNo,
  });

  final PilotDraft draft;
  final PilotMatchKind kind;

  /// The existing profiles that matched under [rule]; empty for a new pilot.
  final List<Id> candidateIds;

  /// The revision each candidate had when it was matched. An update refuses
  /// to run if the stored profile has moved on since.
  final Map<Id, int> candidateRevisions;

  /// True when the pilot's identifiers point at different profiles (for
  /// example the email at one and the FAI number at another). Never updated
  /// automatically.
  final bool conflict;

  /// The strongest rule that found a match; null for a new pilot.
  final PilotMatchRule? rule;

  /// For an exact match: what an update would change. Empty when the profile
  /// already holds everything the file has.
  final List<PilotFieldChange> changes;

  /// Set when an earlier pilot of the same file is the same person by the
  /// same rules.
  final int? duplicateOfSourcePilotNo;

  bool get isDuplicateInFile => duplicateOfSourcePilotNo != null;

  /// True for an exact match with nothing to change.
  bool get isUnchanged => kind == PilotMatchKind.exact && changes.isEmpty;

  PilotImportAction get defaultAction {
    if (isDuplicateInFile) {
      return PilotImportAction.ask;
    }
    return switch (kind) {
      PilotMatchKind.newPilot => PilotImportAction.add,
      PilotMatchKind.exact => PilotImportAction.update,
      PilotMatchKind.likely => PilotImportAction.ask,
    };
  }
}
