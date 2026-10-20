import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_settings.dart';

final _deviceButton = find.byKey(const ValueKey('time-zone-device-button'));
final _followsDevice = find.text('Following this device.');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the time zone and language are chosen on the Settings page', (
    tester,
  ) async {
    await openMainPage(tester);
    await openSettings(tester);

    // Start from the device's own zone, whatever an earlier run left.
    if (_followsDevice.evaluate().isEmpty) {
      await tapVisible(tester, _deviceButton);
    }
    expect(_followsDevice, findsOneWidget);

    // Pick a zone by searching for its city.
    final zoneField = find.descendant(
      of: find.byKey(const ValueKey('settings-page')),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(zoneField.first);
    await tester.enterText(zoneField.first, 'rome');
    await pumpUntilFound(tester, find.textContaining('Rome').last);
    await tester.tap(find.textContaining('Rome').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_followsDevice, findsNothing);

    // Leaving and coming back shows the chosen zone.
    await tapRail(tester, 'Roles');
    await pumpUntilFound(tester, find.text('Pilot'));
    await openSettings(tester);
    expect(_followsDevice, findsNothing);
    expect(find.textContaining('Rome'), findsWidgets);

    // The language choice lists the device and English.
    await tapVisible(tester, find.byKey(const ValueKey('locale-null')));
    await pumpUntilFound(tester, find.text('English (United States)').last);
    await tester.tap(find.text('English (United States)').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('locale-en-US')), findsOneWidget);

    // Leave the app on its defaults for the next run.
    await tapVisible(tester, _deviceButton);
    expect(_followsDevice, findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('locale-en-US')));
    await pumpUntilFound(tester, find.text("Use this device's language").last);
    await tester.tap(find.text("Use this device's language").last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('locale-null')), findsOneWidget);
  });
}
