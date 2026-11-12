import '../id.dart';
import '../participants/participant_profile.dart';
import 'pilot_import_match.dart';

/// What the director decided for one drafted pilot.
enum PilotImportChoice {
  /// Create a new profile.
  add,

  /// Update an existing profile with the file's values.
  update,

  /// Leave the pilot out.
  skip,
}

/// One drafted pilot with the director's decision.
class PilotImportSelection {
  PilotImportSelection({
    required this.match,
    required this.choice,
    this.targetProfileId,
    this.expectedRevision,
    Id? newProfileId,
  }) : newProfileId = newProfileId ?? Id.create();

  /// The default for [match]: add, update or (for a pilot someone has to
  /// decide on) skip until they choose.
  factory PilotImportSelection.defaultFor(PilotMatch match) =>
      switch (match.defaultAction) {
        PilotImportAction.add => PilotImportSelection(
          match: match,
          choice: PilotImportChoice.add,
        ),
        PilotImportAction.update => PilotImportSelection(
          match: match,
          choice: PilotImportChoice.update,
          targetProfileId: match.candidateIds.single,
        ),
        PilotImportAction.ask => PilotImportSelection(
          match: match,
          choice: PilotImportChoice.skip,
          targetProfileId: match.remembered && match.candidateIds.length == 1
              ? match.candidateIds.single
              : null,
        ),
      };

  final PilotMatch match;
  final PilotImportChoice choice;

  /// For [PilotImportChoice.update]: the profile to update. May be left out
  /// when the match found exactly one.
  final Id? targetProfileId;

  /// For [PilotImportChoice.update]: the revision of the target profile that
  /// the review was based on. Defaults to the revision the matcher saw. If
  /// the stored profile has a different revision when the import is applied,
  /// nothing is written and the review has to be redone.
  final int? expectedRevision;

  /// For [PilotImportChoice.add]: the id of the new profile. Fixed when the
  /// selection is made (generated if not given), so applying the same
  /// selection again, for example after an unclear failure, finds the profile
  /// it already stored instead of adding another.
  final Id newProfileId;
}

/// What an import changed.
class PilotImportOutcome {
  const PilotImportOutcome({
    required this.added,
    required this.updated,
    required this.unchanged,
    required this.skipped,
  });

  final List<ParticipantProfile> added;
  final List<ParticipantProfile> updated;

  /// Pilots whose profile already held everything the file has.
  final int unchanged;
  final int skipped;
}
