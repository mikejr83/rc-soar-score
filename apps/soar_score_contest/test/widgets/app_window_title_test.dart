import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/app_window_title.dart';

import '../support/window_title_recorder.dart';

Widget _host(String title) => MaterialApp(
  home: AppWindowTitle(title: title, child: const SizedBox.shrink()),
);

void main() {
  group('windowTitleFor', () {
    test('is the application name without a contest', () {
      expect(windowTitleFor(), 'RC Soar Score');
    });

    test('appends the selected contest name', () {
      expect(
        windowTitleFor(contestName: 'Spring F3J 2026'),
        'RC Soar Score: Spring F3J 2026',
      );
    });
  });

  testWidgets('sends the title to the Windows runner when shown and when it '
      'changes', (tester) async {
    final titles = recordWindowTitles();

    await tester.pumpWidget(_host('First'));
    await tester.pumpWidget(_host('First'));
    await tester.pumpWidget(_host('Second'));

    expect(titles, ['First', 'Second']);
  }, variant: windowsOnly);

  testWidgets('sets the Title widget for the web tab', (tester) async {
    await tester.pumpWidget(_host('Tab title'));

    expect(tester.widget<Title>(find.byType(Title).last).title, 'Tab title');
  });

  testWidgets('does not use the runner channel off Windows', (tester) async {
    final titles = recordWindowTitles();

    await tester.pumpWidget(_host('Ignored'));

    expect(titles, isEmpty);
  });
}
