import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/page_states/page_states.dart';

Future<void> _pump(WidgetTester tester, Widget view) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: view)));

void main() {
  testWidgets('loading shows a spinner and its label', (tester) async {
    await _pump(tester, const PageStateView.loading(label: 'Loading things'));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading things'), findsOneWidget);
  });

  testWidgets('empty shows title, body and the primary action', (tester) async {
    var pressed = 0;
    await _pump(
      tester,
      PageStateView.empty(
        title: 'No things yet.',
        body: 'Add one.',
        primary: PageStateAction(label: 'Add', onPressed: () => pressed++),
      ),
    );

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('No things yet.'), findsOneWidget);
    expect(find.text('Add one.'), findsOneWidget);
    await tester.tap(find.text('Add'));
    expect(pressed, 1);
  });

  testWidgets('empty can hold a custom action', (tester) async {
    await _pump(
      tester,
      const PageStateView.empty(
        title: 'No things yet.',
        action: Text('custom action'),
      ),
    );

    expect(find.text('custom action'), findsOneWidget);
  });

  testWidgets('unavailable offers Retry and an optional second action', (
    tester,
  ) async {
    var retries = 0;
    var others = 0;
    await _pump(
      tester,
      PageStateView.unavailable(
        title: 'Could not load.',
        body: 'The server could not be reached.',
        primary: PageStateAction(label: 'Retry', onPressed: () => retries++),
        secondary: PageStateAction(label: 'Go back', onPressed: () => others++),
      ),
    );

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.tap(find.text('Go back'));
    expect((retries, others), (1, 1));
  });

  testWidgets('each kind has its own icon, not colour alone', (tester) async {
    final views = <(IconData, Widget)>[
      (Icons.lock_outline, const PageStateView.authorization(title: 'No')),
      (Icons.sync_problem, const PageStateView.conflict(title: 'Changed')),
      (Icons.search_off, const PageStateView.notFound(title: 'Not found')),
    ];
    for (final (icon, view) in views) {
      await _pump(tester, view);
      expect(find.byIcon(icon), findsOneWidget);
    }
  });

  testWidgets('failures are announced as alerts, the rest as status', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final views = <(PageStateView, SemanticsRole)>[
      (const PageStateView.unavailable(title: 'T'), SemanticsRole.alert),
      (const PageStateView.authorization(title: 'T'), SemanticsRole.alert),
      (const PageStateView.conflict(title: 'T'), SemanticsRole.alert),
      (const PageStateView.loading(label: 'T'), SemanticsRole.status),
      (const PageStateView.empty(title: 'T'), SemanticsRole.status),
      (const PageStateView.notFound(title: 'T'), SemanticsRole.status),
    ];
    for (final (view, role) in views) {
      await _pump(tester, view);
      final node = tester.getSemantics(
        find.descendant(
          of: find.byType(PageStateView),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.role == role,
          ),
        ),
      );
      expect(node.role, role, reason: '${view.kind}');
    }
    handle.dispose();
  });

  testWidgets('a conflict has no built-in actions', (tester) async {
    await _pump(tester, const PageStateView.conflict(title: 'Changed'));

    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('PageBanner shows icon, text and an action', (tester) async {
    var pressed = 0;
    await _pump(
      tester,
      PageBanner(
        kind: PageBannerKind.alert,
        icon: Icons.sync_problem,
        text: 'This page is out of date.',
        actionLabel: 'Refresh',
        onAction: () => pressed++,
      ),
    );

    expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    expect(find.text('This page is out of date.'), findsOneWidget);
    await tester.tap(find.text('Refresh'));
    expect(pressed, 1);
  });

  testWidgets('StatusLabel speaks the field and the value', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const StatusLabel(
        field: 'Lifecycle',
        value: 'Running',
        child: Text('Running'),
      ),
    );

    expect(find.bySemanticsLabel('Lifecycle: Running'), findsOneWidget);
    handle.dispose();
  });
}
