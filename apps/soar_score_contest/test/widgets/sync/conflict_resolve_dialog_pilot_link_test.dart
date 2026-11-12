import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/services/pilot_import/pilot_import.dart';
import 'package:soar_score_contest/services/sync/conflict_answer.dart';
import 'package:soar_score_contest/services/sync/open_conflict.dart';
import 'package:soar_score_contest/widgets/sync/conflict_resolve_dialog.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/pilot_import_fakes.dart';

void main() {
  late ParticipantProfile ada;
  late ParticipantProfile grace;
  late OpenConflict conflict;
  PilotImportStore? previous;

  setUp(() {
    ada = profile(first: 'Ada', last: 'Lovelace');
    grace = profile(first: 'Grace', last: 'Hopper');
    previous = PilotImportStore.current;
    PilotImportStore.current = FakePilotImportStore([ada, grace]);
    conflict = OpenConflict(
      id: Id.create(),
      entityType: 'PilotImportLink',
      entityId: Id.create(),
      createdAt: DateTime.utc(2026, 10, 13, 18),
      reasonCode: 'unique_violation',
      acceptedPayload: {
        'source_pilot_no': 12,
        'participant_profile_id': ada.id.value,
      },
      competingPayload: {
        'source_pilot_no': 12,
        'participant_profile_id': grace.id.value,
      },
    );
  });
  tearDown(() => PilotImportStore.current = previous);

  final payloads = <Map<String, Object?>?>[];

  Future<List<ConflictResolutionChoice>> open(
    WidgetTester tester,
    ConflictAnswer answer, {
    List<ConflictAnswer?>? closedWith,
  }) async {
    payloads.clear();
    final asked = <ConflictResolutionChoice>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showDialog<ConflictAnswer>(
                context: context,
                builder: (_) => ConflictResolveDialog(
                  conflict: conflict,
                  onResolve: (choice, payload) async {
                    asked.add(choice);
                    payloads.add(payload);
                    return answer;
                  },
                ),
              );
              closedWith?.add(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return asked;
  }

  testWidgets('shows the pilot number and both participants by name', (
    tester,
  ) async {
    await open(tester, const ConflictAnswer.resolved());

    expect(find.text('GliderScore pilot 12'), findsOneWidget);
    expect(find.text('Link the account has now: Ada Lovelace'), findsOneWidget);
    expect(
      find.text('Link from the other device: Grace Hopper'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('conflict-edit')), findsNothing);
  });

  testWidgets('each button names the participant it keeps', (tester) async {
    await open(tester, const ConflictAnswer.resolved());

    expect(find.text('Keep Ada Lovelace'), findsOneWidget);
    expect(find.text('Use Grace Hopper'), findsOneWidget);
  });

  testWidgets('using the other link sends TookCompeting and closes', (
    tester,
  ) async {
    final closed = <ConflictAnswer?>[];
    final asked = await open(
      tester,
      const ConflictAnswer.resolved(),
      closedWith: closed,
    );

    await tester.tap(find.byKey(const ValueKey('conflict-take-competing')));
    await tester.pumpAndSettle();

    expect(asked, [ConflictResolutionChoice.tookCompeting]);
    expect(find.byKey(const ValueKey('conflict-dialog')), findsNothing);
    expect(closed.single!.resolved, isTrue);
  });

  testWidgets('a review the service replaced closes so the page refreshes', (
    tester,
  ) async {
    final closed = <ConflictAnswer?>[];
    await open(
      tester,
      const ConflictAnswer.notAccepted('Stale base.'),
      closedWith: closed,
    );

    await tester.tap(find.byKey(const ValueKey('conflict-keep-accepted')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('conflict-dialog')), findsNothing);
    expect(closed.single!.resolved, isFalse);
    expect(closed.single!.refusal, 'Stale base.');
  });

  testWidgets('the director can choose another participant', (tester) async {
    final closed = <ConflictAnswer?>[];
    final asked = await open(
      tester,
      const ConflictAnswer.resolved(),
      closedWith: closed,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('conflict-use-picked')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('conflict-pick-participant')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grace Hopper').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('conflict-use-picked')));
    await tester.pumpAndSettle();

    expect(asked, [ConflictResolutionChoice.merged]);
    expect(payloads.single, {'participant_profile_id': grace.id.value});
    expect(closed.single!.resolved, isTrue);
  });

  testWidgets('a picked participant who is gone keeps the dialog open', (
    tester,
  ) async {
    await open(tester, const ConflictAnswer.notAccepted('Entity deleted.'));

    await tester.tap(find.byKey(const ValueKey('conflict-pick-participant')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grace Hopper').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('conflict-use-picked')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('conflict-dialog')), findsOneWidget);
    expect(find.textContaining('no longer available'), findsOneWidget);
  });

  testWidgets('a participant who is gone is named as such', (tester) async {
    PilotImportStore.current = FakePilotImportStore([ada]);

    await open(tester, const ConflictAnswer.resolved());

    expect(
      find.text(
        'Link from the other device: a participant who is not in your list',
      ),
      findsOneWidget,
    );
  });
}
