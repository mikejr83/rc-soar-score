import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soar_score_contest/services/text_size/text_size.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_settings.dart';

final _control = find.byKey(const ValueKey('text-size-control'));
final _preview = find.byKey(const ValueKey('text-size-preview'));

Set<TextSize> _selected(WidgetTester tester) =>
    tester.widget<SegmentedButton<TextSize>>(_control).selected;

Future<void> _choose(WidgetTester tester, String label) => tapVisible(
  tester,
  find.descendant(of: _control, matching: find.text(label)),
);

double _previewHeight(WidgetTester tester) => tester.getSize(_preview).height;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the text size is chosen on the Settings page and kept', (
    tester,
  ) async {
    await openMainPage(tester);
    await openSettings(tester);

    // The choice lives in the client's UI store, which a demo reset does not
    // clear, so start by putting it to Default.
    await _choose(tester, 'Default');
    final defaultHeight = _previewHeight(tester);

    await _choose(tester, 'Large');
    expect(_selected(tester), {TextSize.large});
    final largeHeight = _previewHeight(tester);
    expect(largeHeight, greaterThan(defaultHeight));

    // The shell and the contest list still draw at the larger size.
    await tapRail(tester, 'Contests');
    await pumpUntilFound(tester, find.text('Contests'));
    expect(tester.takeException(), isNull);

    await openSettings(tester);
    await _choose(tester, 'Extra large');
    expect(_previewHeight(tester), greaterThan(largeHeight));

    // Leaving and coming back shows the saved choice.
    await tapRail(tester, 'Roles');
    await pumpUntilFound(tester, find.text('Pilot'));
    await openSettings(tester);
    expect(_selected(tester), {TextSize.extraLarge});

    // Leave the app on its default for the next run.
    await _choose(tester, 'Default');
    expect(_previewHeight(tester), defaultHeight);
  });
}
