import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/app_mode_provider.dart';
import 'package:soar_score_contest/contest_draft_provider.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft_store.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'participant_test_support.dart';

/// A contest the copy source picker can list.
Contest sourceContest({
  String name = 'Labor Day F5J Open',
  String id = '019c0000-0000-7000-8000-0000000000a1',
}) => Contest(
  id: Id.parse(id),
  name: name,
  startDateTime: DateTime.utc(2026, 9, 5, 14),
  endDateTime: DateTime.utc(2026, 9, 6, 14),
  timezone: 'America/New_York',
  createdAt: DateTime.utc(2026, 8),
  updatedAt: DateTime.utc(2026, 8),
);

/// An F5J configuration with teams (3 counted) and classes on.
ContestConfigurationRevision sourceConfiguration(Contest contest) =>
    ContestConfigurationRevision(
      id: Id.parse('019c0000-0000-7000-8000-0000000000b1'),
      contestId: contest.id,
      revisionNumber: 1,
      disciplineProfileId: SystemDisciplineProfiles.f5jId,
      config: ContestConfig(
        core: const {
          'teams_enabled': true,
          'team_pilot_count': 3,
          'classes_enabled': true,
        },
        discipline: const {},
      ),
      createdBy: Id.parse(ownerId),
      createdAt: DateTime.utc(2026, 8),
    );

/// A participation of profile [n] in [contest].
ContestParticipation participation(
  Contest contest,
  int n, {
  String? classification,
  bool pilot = true,
}) => ContestParticipation(
  id: Id.parse('019c0000-0000-7000-8000-0000000001$n'),
  contestId: contest.id,
  participantProfileId: Id.parse('019c0000-0000-7000-8000-0000000000$n'),
  classification: pilot ? classification : null,
  roleId: pilot ? SystemRoles.pilotId : SystemRoles.helperId,
  roleName: pilot ? 'Pilot' : 'Helper',
  roleType: pilot ? RoleType.pilot : RoleType.nonFlier,
  scoringUuid: ScoringUuid.create(),
);

/// Pumps the real app router at the wizard (or [initial]) with [store] as
/// the app-wide draft, answering API requests with [respond].
Future<PumpedWizard> pumpWizard(
  WidgetTester tester, {
  required Future<http.Response> Function(http.Request) respond,
  ContestDraftStore? store,
  String initial = newContestPath,
  Size size = const Size(1280, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final draftStore = store ?? ContestDraftStore();
  final router = buildAppRouter(
    initialLocation: initial,
    appMode: AppModeNotifier(isOfflineMode: true),
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ContestDraftInherited(
      store: draftStore,
      child: ApiClientInherited(
        client: clientFor(respond),
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return PumpedWizard(router, draftStore);
}

/// The router and draft store behind a pumped wizard.
class PumpedWizard {
  PumpedWizard(this.router, this.store);

  final GoRouter router;
  final ContestDraftStore store;
}

/// Answers with no contests and no participants.
Future<http.Response> emptyApi(http.Request request) async {
  if (request.url.path.endsWith('/contests')) {
    return json({'contests': []});
  }
  return json({'participants': []});
}

/// Fills the required step 1 fields.
Future<void> fillDetails(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('contest-name')),
    'Gator Cup F5J',
  );
  await tester.enterText(
    find.byKey(const ValueKey('contest-venue')),
    'Flying Gators · Hague Field',
  );
  await tester.enterText(
    find.byKey(const ValueKey('contest-start')),
    'Nov 14, 2026',
  );
  await tester.enterText(
    find.byKey(const ValueKey('contest-end')),
    'Nov 15, 2026',
  );
  await tester.pump();
}

/// Presses the footer's primary action.
Future<void> next(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('wizard-primary')));
  await tester.tap(find.byKey(const ValueKey('wizard-primary')));
  await tester.pumpAndSettle();
}

/// The current step's title.
String stepTitle(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('wizard-step-title'))).data!;
