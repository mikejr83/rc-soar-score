import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/contest/workspace_page.dart';
import 'package:soar_score_contest/services/competition_import/competition_import.dart';
import 'package:soar_score_contest/widgets/contest_scope.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/competition_import_fakes.dart';

const _idA = '019c0000-0000-7000-8000-00000000000a';
const _idB = '019c0000-0000-7000-8000-00000000000b';
const _banner = ValueKey('workspace-banner-imported');

Contest _contest(String id) => Contest(
  id: Id.parse(id),
  name: 'Contest $id',
  startDateTime: DateTime.utc(2026, 10, 17, 14),
  endDateTime: DateTime.utc(2026, 10, 18, 14),
  timezone: 'America/Denver',
  host: 'Host',
  lifecycleState: LifecycleState.configuring,
  scoringAccess: ScoringAccess.closed,
  adminLock: AdminLock.unlocked,
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
);

ImportedContestNote _note() => ImportedContestNote(
  importedAt: DateTime.utc(2026, 11, 4),
  drawImported: true,
  lanesKept: true,
);

/// Answers each contest's lookup when the test says so.
class _SlowStore extends FakeCompetitionImportStore {
  _SlowStore() : super(const []);

  final pending = <String, Completer<ImportedContestNote?>>{};

  @override
  Future<ImportedContestNote?> noteFor(Id contestId) =>
      (pending[contestId.value] ??= Completer()).future;
}

void main() {
  late _SlowStore store;
  final shown = ValueNotifier<String>(_idA);

  setUp(() {
    store = _SlowStore();
    CompetitionImportStore.current = store;
    shown.value = _idA;
  });
  tearDown(() => CompetitionImportStore.current = null);

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ValueListenableBuilder<String>(
          valueListenable: shown,
          builder: (_, id, _) => ContestScope(
            contest: _contest(id),
            reload: () async => true,
            child: ContestWorkspacePage(contestId: id),
          ),
        ),
      ),
    ),
  );

  testWidgets('the note of the last contest does not show on the next', (
    tester,
  ) async {
    await pump(tester);
    store.pending[_idA]!.complete(_note());
    await tester.pump();
    await tester.pump();
    expect(find.byKey(_banner), findsOneWidget);

    shown.value = _idB;
    await tester.pump();
    expect(
      find.byKey(_banner),
      findsNothing,
      reason: 'B has no answer yet and must not borrow the note of A',
    );
    store.pending[_idB]!.complete(null);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(_banner), findsNothing);
  });

  testWidgets('a slow answer for the last contest is ignored', (tester) async {
    await pump(tester);
    shown.value = _idB;
    await tester.pump();
    store.pending[_idB]!.complete(null);
    await tester.pump();
    store.pending[_idA]!.complete(_note());
    await tester.pump();
    await tester.pump();
    expect(find.byKey(_banner), findsNothing);
  });

  testWidgets('coming back to a contest shows its note again', (tester) async {
    await pump(tester);
    store.pending[_idA]!.complete(_note());
    await tester.pump();
    shown.value = _idB;
    await tester.pump();
    store.pending[_idB]!.complete(null);
    await tester.pump();
    shown.value = _idA;
    await tester.pump();
    await tester.pump();
    expect(find.byKey(_banner), findsOneWidget);
  });
}
