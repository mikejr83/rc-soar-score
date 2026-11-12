import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app_sync_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/contest/sync_page.dart';
import 'package:soar_score_contest/services/pilot_import/pilot_import.dart';
import 'package:soar_score_contest/services/sync/app_sync_state.dart';
import 'package:soar_score_contest/services/sync/conflict_answer.dart';
import 'package:soar_score_contest/services/sync/open_conflict.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/fake_app_sync.dart';
import '../support/pilot_import_fakes.dart';
import '../support/preferences_scope.dart';

void main() {
  final director = Id.create();
  final scope = DirectorScopeKey(director);
  late ParticipantProfile ada;
  late ParticipantProfile grace;
  late ParticipantProfile edith;
  PilotImportStore? previous;

  OpenConflict review(ParticipantProfile kept, ParticipantProfile other) =>
      OpenConflict(
        id: Id.create(),
        entityType: 'PilotImportLink',
        entityId: Id.create(),
        createdAt: DateTime.utc(2026, 10, 13, 18),
        reasonCode: 'unique_violation',
        acceptedPayload: {
          'source_pilot_no': 12,
          'participant_profile_id': kept.id.value,
        },
        competingPayload: {
          'source_pilot_no': 12,
          'participant_profile_id': other.id.value,
        },
      );

  setUp(() {
    ada = profile(first: 'Ada', last: 'Lovelace');
    grace = profile(first: 'Grace', last: 'Hopper');
    edith = profile(first: 'Edith', last: 'Clarke');
    previous = PilotImportStore.current;
    PilotImportStore.current = FakePilotImportStore([ada, grace, edith]);
  });
  tearDown(() => PilotImportStore.current = previous);

  Future<FakeAppSync> pump(
    WidgetTester tester,
    List<OpenConflict> conflicts,
  ) async {
    final sync = FakeAppSync(
      state: AppSyncState(
        scopes: {scope: SyncScopeSummary(conflicts: conflicts.length)},
      ),
    )..accountScope = scope;
    sync.conflicts = conflicts;
    await tester.pumpWidget(
      withPreferredZone(
        AppSyncInherited(
          sync: sync,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AccountSyncPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return sync;
  }

  testWidgets('lists a pilot link review by its pilot number', (tester) async {
    final conflict = review(ada, grace);
    await pump(tester, [conflict]);

    expect(find.text('Account sync'), findsOneWidget);
    expect(find.textContaining('GliderScore pilot 12'), findsOneWidget);
    expect(
      find.byKey(ValueKey('conflict-review-${conflict.id}')),
      findsOneWidget,
    );
  });

  testWidgets('the director keeps either link by name', (tester) async {
    final conflict = review(ada, grace);
    final sync = await pump(tester, [conflict]);

    await tester.tap(find.byKey(ValueKey('conflict-review-${conflict.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Keep Ada Lovelace'), findsOneWidget);
    expect(find.text('Use Grace Hopper'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('conflict-take-competing')));
    await tester.pumpAndSettle();

    expect(
      sync.resolutions.single.choice,
      ConflictResolutionChoice.tookCompeting,
    );
    expect(find.text('Decision saved.'), findsOneWidget);
  });

  testWidgets('a review that changed under the director is shown again', (
    tester,
  ) async {
    final shown = review(ada, grace);
    final sync = await pump(tester, [shown]);
    sync.answer = const ConflictAnswer.notAccepted('Stale base.');

    await tester.tap(find.byKey(ValueKey('conflict-review-${shown.id}')));
    await tester.pumpAndSettle();
    // The service replaced the review: the same pilot, a different link.
    final replaced = review(edith, grace);
    sync.conflicts = [replaced];
    await tester.tap(find.byKey(const ValueKey('conflict-keep-accepted')));
    await tester.pumpAndSettle();

    expect(sync.synced, [scope]);
    expect(
      find.textContaining('changed while you were reviewing'),
      findsOneWidget,
    );
    expect(find.byKey(ValueKey('conflict-review-${shown.id}')), findsNothing);
    expect(
      find.byKey(ValueKey('conflict-review-${replaced.id}')),
      findsOneWidget,
    );
    // Nothing was decided; the new comparison asks again.
    await tester.tap(find.byKey(ValueKey('conflict-review-${replaced.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Keep Edith Clarke'), findsOneWidget);
  });
}
