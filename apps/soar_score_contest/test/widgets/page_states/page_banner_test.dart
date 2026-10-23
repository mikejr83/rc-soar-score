import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/page_states/page_states.dart';

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

void main() {
  testWidgets('shows title, text and child, and runs every action', (
    tester,
  ) async {
    final pressed = <String>[];
    await _pump(
      tester,
      PageBanner(
        kind: PageBannerKind.info,
        shape: PageBannerShape.card,
        icon: Icons.info,
        title: 'A title',
        text: 'Some text',
        actionLabel: 'First',
        onAction: () => pressed.add('first'),
        secondaryLabel: 'Second',
        onSecondary: () => pressed.add('second'),
        actions: [
          PageBannerAction(
            'Third',
            () => pressed.add('third'),
            emphasis: PageBannerEmphasis.outlined,
          ),
          PageBannerAction(
            'Fourth',
            () => pressed.add('fourth'),
            emphasis: PageBannerEmphasis.filled,
            key: const ValueKey('fourth'),
          ),
        ],
        child: const Text('A link'),
      ),
    );

    expect(find.text('A title'), findsOneWidget);
    expect(find.text('Some text'), findsOneWidget);
    expect(find.text('A link'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byKey(const ValueKey('fourth')), findsOneWidget);
    for (final label in ['First', 'Second', 'Third', 'Fourth']) {
      await tester.tap(find.text(label));
    }
    expect(pressed, ['first', 'second', 'third', 'fourth']);
  });

  testWidgets('empty text draws no text line and a null callback disables', (
    tester,
  ) async {
    await _pump(
      tester,
      const PageBanner(
        kind: PageBannerKind.neutral,
        icon: Icons.info,
        title: 'Only a title',
        text: '',
        actionLabel: 'Go',
      ),
    );

    expect(find.byType(Text), findsNWidgets(2));
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
  });

  test('only the alert kind has the alert role', () {
    for (final kind in PageBannerKind.values) {
      expect(
        kind.role,
        kind == PageBannerKind.alert
            ? SemanticsRole.alert
            : SemanticsRole.status,
      );
    }
  });
}
