import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/copy_mode.dart';
import 'package:soar_score_contest/services/new_contest/copy_source.dart';
import 'package:soar_score_contest/services/new_contest/draft_participant.dart';
import 'package:soar_score_contest/services/new_contest/draw_settings.dart';
import 'package:soar_score_contest/services/new_contest/participant_option.dart';
import 'package:soar_score_contest/services/new_contest/scoring_settings.dart';
import 'package:soar_score_contest/services/new_contest/wizard_discipline.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'new_contest_test_support.dart';

/// A draft with every field set to something other than its default.
ContestDraft richDraft() {
  final source = sourceContest();
  return ContestDraft(
    name: 'Gator Cup F5J',
    venue: 'Flying Gators · Hague Field',
    startDate: 'Nov 14, 2026',
    endDate: 'Nov 15, 2026',
    city: 'Hague',
    region: 'FL',
    country: 'US',
    timeZone: 'America/New_York',
    copyMode: CopyMode.selectedPilots,
    source: CopySource(
      contest: source,
      discipline: WizardDiscipline.f5j,
      pilots: [
        SourcePilot(
          profileId: Id.parse('019c0000-0000-7000-8000-000000000002'),
          name: 'Avery Brooks',
          email: 'avery@example.com',
          classification: 'Open',
        ),
      ],
    ),
    selectedPilots: {'019c0000-0000-7000-8000-000000000002'},
    discipline: WizardDiscipline.f5j,
    options: {ParticipantOption.teams, ParticipantOption.classes},
    optionsFromSource: {ParticipantOption.teams},
    teamPilotCount: '3',
    participants: [
      DraftParticipant(
        profileId: Id.parse('019c0000-0000-7000-8000-000000000002'),
        name: 'Avery Brooks',
        email: 'avery@example.com',
        emailVisible: false,
        source: ParticipantSource.remote,
        roleName: 'Pilot',
        classification: 'Open',
        team: 'Gators',
        model: 'Supra',
        modelId: 'S-1',
      ),
    ],
    scoring: const ScoringSettings(
      groupScoreMode: GroupScoreMode.normalized,
      roundingMode: RoundingMode.truncate,
      decimalPlaces: 2,
      dropPolicy: DropPolicy.two,
      firstDrop: '4',
      secondDrop: 'x',
      reviewRequests: false,
      publicUpdateMode: PublicUpdateMode.roundCompletion,
    ),
    draw: const DrawSettings(
      drawMode: DrawMode.seededManOnMan,
      groups: '3',
      rounds: '9',
      laneMode: LaneMode.random,
      teamProtection: true,
      allowBackToBack: false,
      seededRounds: '2',
    ),
    visitedThrough: 5,
  );
}
