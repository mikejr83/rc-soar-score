import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/router.dart';

import '../journey/phase_2_invitation.dart';
import 'director_api.dart';
import 'launch_app.dart';

/// Opens [name]'s link and continues as guest, replacing any session in this
/// browser. Returns the pilot id of the new session.
Future<String> signInAs(
  WidgetTester tester,
  SeededContest contest,
  String name,
) async {
  await openPath(tester, invitationPath(contest.credentialOf(name)));
  await pumpUntilFound(tester, find.text('Hello, $name'));
  await tapVisible(tester, find.text('Continue as guest'));
  await pumpUntilFound(tester, find.text('2 rounds'));
  final uri = router.routeInformationProvider.value.uri;
  return uri.pathSegments[uri.pathSegments.indexOf('pilots') + 1];
}
