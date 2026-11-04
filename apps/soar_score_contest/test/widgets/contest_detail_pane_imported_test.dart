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
    name: 'Spring Open',
    startDateTime: DateTime.utc(2026, 5, 9),
    endDateTime: DateTime.utc(2026, 5, 10),
    timezone: 'America/Denver',
    createdAt: DateTime.utc(2026, 5),
    updatedAt: DateTime.utc(2026, 5),
  );

  Future<void> pump(WidgetTester tester, {DateTime? importedAt}) =>
      tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ContestDetailPane(
              contest: contest,
              onOpen: () {},
              importedAt: importedAt,
            ),
          ),
        ),
      );

  testWidgets('an imported contest carries the chip', (tester) async {
    await pump(tester, importedAt: DateTime.utc(2026, 11, 4, 12));
    expect(find.byKey(const ValueKey('imported-label')), findsOneWidget);
    expect(find.text(l10n.importedChipLabel), findsOneWidget);
  });

  testWidgets('the chip says when the contest was imported', (tester) async {
    await pump(tester, importedAt: DateTime.utc(2026, 11, 4, 12));
    final tooltip = tester.widget<Tooltip>(
      find.ancestor(
        of: find.byKey(const ValueKey('imported-label')),
        matching: find.byType(Tooltip),
      ),
    );
    expect(tooltip.message, startsWith('Imported from GliderScore on '));
    expect(tooltip.message, contains('2026'));
  });

  testWidgets('an ordinary contest has no chip', (tester) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('imported-label')), findsNothing);
  });
}
