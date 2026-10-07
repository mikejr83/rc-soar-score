import 'package:soar_score_core/soar_score_core.dart';

import 'contest_draft.dart';
import 'copy_mode.dart';
import 'copy_source.dart';
import 'draft_participant.dart';
import 'participant_option.dart';

/// Copying from a source contest into the draft.
///
/// Configuration copies the discipline and participant options. Pilots
/// copy only their participation and class; teams, models, non-flying
/// participants, scores, the matrix, publication history, invitations and
/// audit history are never copied.
extension DraftCopy on ContestDraft {
  /// The options turned on in [options], in wizard terms.
  static Set<ParticipantOption> optionsOf(CoreOptions options) => {
    if (options.teamsEnabled) ParticipantOption.teams,
    if (options.participantNumbersEnabled) ParticipantOption.pilotNumbers,
    if (options.classesEnabled) ParticipantOption.classes,
    if (options.rolesEnabled) ParticipantOption.roles,
    if (options.modelsEnabled) ParticipantOption.models,
  };

  /// The draft with [source] loaded: its configuration replaces the
  /// discipline and options, and its pilots are selected per [copyMode].
  ContestDraft withSource(CopySource source) {
    final core = source.options;
    final fromSource = core == null ? <ParticipantOption>{} : optionsOf(core);
    return copyWith(
      source: source,
      discipline: source.discipline ?? discipline,
      options: core == null ? options : fromSource,
      optionsFromSource: fromSource,
      teamPilotCount: core?.teamPilotCount?.toString() ?? teamPilotCount,
      selectedPilots: {
        for (final pilot in source.pilots) pilot.profileId.value,
      },
    ).withCopiedPilots();
  }

  /// The draft without a source; values already copied stay editable.
  ContestDraft withoutSource() => copyWith(
    source: null,
    selectedPilots: const {},
    optionsFromSource: const {},
    participants: const [],
  );

  /// The participants that [copyMode] and [selectedPilots] bring from the
  /// source.
  ContestDraft withCopiedPilots() {
    final source = this.source;
    if (source == null || !copyMode.copiesPilots) {
      return copyWith(participants: const []);
    }
    return copyWith(
      participants: [
        for (final pilot in source.pilots)
          if (copyMode == CopyMode.allPilots ||
              selectedPilots.contains(pilot.profileId.value))
            DraftParticipant(
              profileId: pilot.profileId,
              name: pilot.name,
              email: pilot.email,
              classification: pilot.classification ?? '',
            ),
      ],
    );
  }
}
