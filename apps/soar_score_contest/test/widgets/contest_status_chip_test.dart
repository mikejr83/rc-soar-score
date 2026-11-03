import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/widgets/contest_status_chip.dart';
import 'package:soar_score_core/soar_score_core.dart';

final l10n = AppLocalizationsEn();

void main() {
  testWidgets('the chip is spoken with its field and value', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: ContestStatusChip(state: LifecycleState.running)),
      ),
    );

    // The visible word and icon stay; the label adds what it is the value of.
    expect(find.text(l10n.lifecycleRunning), findsOneWidget);
    expect(find.byIcon(Icons.timer), findsOneWidget);
    expect(find.bySemanticsLabel('Lifecycle: Running'), findsOneWidget);
    handle.dispose();
  });
}
