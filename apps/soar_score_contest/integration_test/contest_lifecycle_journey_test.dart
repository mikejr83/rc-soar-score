import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'journey/journey.dart';
import 'journey/phase_1_start.dart';
import 'journey/phase_2_participants.dart';
import 'journey/phase_3_wizard.dart';
import 'journey/phase_4_setup.dart';
import 'journey/phase_5_run.dart';
import 'journey/phase_6_finish.dart';

/// One contest from the landing page on: participants, the wizard, set-up,
/// scoring and results, as a director would run it. Phases live in
/// `journey/`; `--dart-define=E2E_STOP_AFTER=<n>` (or the `E2E_STOP_AFTER`
/// environment variable of the scripts) ends the run after phase n.
///
/// Journeys that need a special starting state, a fault hook or native
/// dialogs stay in their own files; see `apps/soar_score_contest/AGENTS.md`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('contest lifecycle: start to results', (tester) async {
    final journey = Journey(tester, binding);
    final data = JourneyContext();

    await journey.phase(1, 'Start', () => runStartPhase(journey, data));
    await journey.phase(
      2,
      'Participants',
      () => runParticipantsPhase(journey, data),
    );
    await journey.phase(3, 'Wizard', () => runWizardPhase(journey, data));
    await journey.phase(4, 'Set up', () => runSetupPhase(journey, data));
    await journey.phase(5, 'Run', () => runRunPhase(journey, data));
    await journey.phase(6, 'Finish', () => runFinishPhase(journey, data));

    journey.finish();
  }, timeout: const Timeout(Duration(minutes: 30)));
}
