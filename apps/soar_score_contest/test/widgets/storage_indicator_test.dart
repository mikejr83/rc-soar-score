import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/services/storage/storage_monitor.dart';
import 'package:soar_score_contest/widgets/storage_indicator.dart';

Future<StorageMonitor> _pump(
  WidgetTester tester,
  Future<void> Function() probe,
) async {
  final monitor = StorageMonitor(probe: probe, pollInterval: null);
  addTearDown(monitor.dispose);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StorageIndicator(monitor)),
    ),
  );
  await tester.pump();
  return monitor;
}

void main() {
  testWidgets('shows an icon and text when the storage is available', (
    tester,
  ) async {
    await _pump(tester, () async {});

    expect(find.text('Local storage · Available'), findsOneWidget);
    expect(find.byIcon(Icons.storage), findsOneWidget);
  });

  testWidgets('says so when the storage is unavailable, with the reason and '
      'a retry in the detail view', (tester) async {
    var broken = true;
    await _pump(tester, () async {
      if (broken) throw StateError('disk is gone');
    });
    expect(find.text('Local storage · Unavailable'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('storage-chip')));
    await tester.pumpAndSettle();
    expect(find.text('Status: Unavailable'), findsOneWidget);
    expect(find.textContaining('disk is gone'), findsOneWidget);
    expect(find.textContaining('Last observed: '), findsOneWidget);
    expect(find.text('Last observed: Never'), findsNothing);

    broken = false;
    await tester.tap(find.byKey(const ValueKey('storage-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Status: Available'), findsOneWidget);
    expect(find.byKey(const ValueKey('storage-error')), findsNothing);
  });
}
