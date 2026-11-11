import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'journey/journey.dart';
import 'journey/phase_1_setup.dart';
import 'journey/phase_2_invitation.dart';
import 'journey/phase_3_entry.dart';
import 'journey/phase_4_order.dart';
import 'journey/phase_5_director.dart';
import 'journey/phase_6_results.dart';
import 'journey/phase_7_completion.dart';

/// The self-scoring app from the pilot's side, from invitation link to
/// entered score, against the E2E server (`scripts/e2e-score.sh`). One launch,
/// many steps: the phases are steps of this one test, as in the contest app's
/// lifecycle journey. Rules for extending it: `apps/soar_score_self_score/AGENTS.md`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('self-scoring lifecycle journey', (tester) async {
    final journey = Journey(tester, binding);
    final contest = await phase1Setup(tester, journey);
    final pilotId = await phase2Invitation(tester, journey, contest);
    await phase3Entry(tester, journey, contest, pilotId);
    final secondId = await phase4Order(tester, journey, contest);
    final firstId = await phase5Director(tester, journey, contest, secondId);
    await phase6Results(tester, journey, contest, firstId);
    await phase7Completion(tester, journey, contest, firstId);
    journey.finish();
  }, timeout: const Timeout(Duration(minutes: 15)));
}
