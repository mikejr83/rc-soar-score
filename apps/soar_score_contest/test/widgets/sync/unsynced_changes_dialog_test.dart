import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/widgets/sync/unsynced_changes_dialog.dart';

Future<bool?> _ask(WidgetTester tester, int pending, {String? tap}) async {
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await confirmDiscardUnsynced(
            context,
            pendingChanges: pending,
          ),
          child: const Text('go'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
  if (tap != null) {
    await tester.tap(find.byKey(ValueKey(tap)));
    await tester.pumpAndSettle();
  }
  return result;
}

void main() {
  testWidgets('does not ask when nothing is waiting', (tester) async {
    expect(await _ask(tester, 0), isTrue);
    expect(find.byKey(const ValueKey('unsynced-changes-dialog')), findsNothing);
  });

  testWidgets('names the number of changes and stops on Cancel', (
    tester,
  ) async {
    final result = await _ask(tester, 3, tap: 'unsynced-cancel');

    expect(result, isFalse);
  });

  testWidgets('goes on after Continue anyway', (tester) async {
    expect(await _ask(tester, 1, tap: 'unsynced-continue'), isTrue);
  });

  testWidgets('says how many changes are waiting', (tester) async {
    await _ask(tester, 3);

    expect(find.textContaining('3 changes have not been sent'), findsOneWidget);
  });
}
