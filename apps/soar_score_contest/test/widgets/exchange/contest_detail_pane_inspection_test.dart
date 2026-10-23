import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/widgets/contest_detail_pane.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final contest = Contest(
    id: Id.create(),
    name: 'Autumn Meet',
    startDateTime: DateTime.utc(2026, 10, 17),
    endDateTime: DateTime.utc(2026, 10, 18),
    timezone: 'America/Denver',
    createdAt: DateTime.utc(2026, 10),
    updatedAt: DateTime.utc(2026, 10),
  );

  Future<void> pump(
    WidgetTester tester, {
    bool inspection = false,
    VoidCallback? onExport,
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ContestDetailPane(
          contest: contest,
          onOpen: () {},
          inspection: inspection,
          onExport: onExport,
        ),
      ),
    ),
  );

  testWidgets('an inspection copy is labelled and explained', (tester) async {
    await pump(tester, inspection: true);

    expect(find.text(l10n.inspectionChipLabel), findsOneWidget);
    expect(find.text(l10n.inspectionNotice), findsOneWidget);
    expect(find.byKey(const ValueKey('inspection-notice')), findsOneWidget);
  });

  testWidgets('an ordinary contest carries no label', (tester) async {
    await pump(tester);

    expect(find.byKey(const ValueKey('inspection-label')), findsNothing);
    expect(find.byKey(const ValueKey('inspection-notice')), findsNothing);
  });

  testWidgets('Export is offered only when the build can export', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('export-contest')), findsNothing);

    var exported = 0;
    await pump(tester, onExport: () => exported++);
    await tester.tap(find.byKey(const ValueKey('export-contest')));

    expect(exported, 1);
  });
}
