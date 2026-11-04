import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_banners.dart';
import 'package:soar_score_core/soar_score_core.dart';

const _key = ValueKey('workspace-banner-imported');
final _l10n = AppLocalizationsEn();

Future<void> _pump(WidgetTester tester, ImportedContestNote? note) =>
    tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: WorkspaceBanners(importNote: note)),
      ),
    );

ImportedContestNote _note({bool lanes = true}) => ImportedContestNote(
  importedAt: DateTime.utc(2026, 11, 4, 12),
  lanesKept: lanes,
);

void main() {
  testWidgets('a contest that was not imported has no note', (tester) async {
    await _pump(tester, null);
    expect(find.byKey(_key), findsNothing);
  });

  testWidgets('says the contest is as GliderScore held it', (tester) async {
    await _pump(tester, _note());
    expect(find.byKey(_key), findsOneWidget);
    expect(find.textContaining(_l10n.importedContestNoteBody), findsOneWidget);
    expect(find.textContaining(_l10n.importedContestNoteNoLanes), findsNothing);
  });

  testWidgets('says when the draw has no lanes', (tester) async {
    await _pump(tester, _note(lanes: false));
    expect(
      find.textContaining(_l10n.importedContestNoteNoLanes),
      findsOneWidget,
    );
  });
}
