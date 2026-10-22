import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/widgets/discard_changes_dialog.dart';
import 'package:soar_score_contest/widgets/page_states/page_states.dart';

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

ApiHttpError _http(int status) => ApiHttpError(
  'failed',
  statusCode: status,
  body: '',
  requestUri: Uri.parse('http://localhost/x'),
);

void main() {
  testWidgets('a retryable failure offers Retry and Dismiss', (tester) async {
    var retries = 0;
    var dismissals = 0;
    await _pump(
      tester,
      SaveFailedBanner(
        message: 'Try again shortly.',
        retryable: true,
        onRetry: () => retries++,
        onDismiss: () => dismissals++,
        messageKey: const ValueKey('message'),
      ),
    );

    final text =
        (find.byKey(const ValueKey('message')).evaluate().single.widget as Text)
            .data!;
    expect(text, contains('Try again shortly.'));
    expect(text, contains('Everything you entered is kept.'));
    await tester.tap(find.text('Retry'));
    await tester.tap(find.text('Dismiss'));
    expect((retries, dismissals), (1, 1));
  });

  testWidgets('a failure that needs a change has no Retry', (tester) async {
    await _pump(
      tester,
      SaveFailedBanner(
        message: 'Name is too long.',
        retryable: false,
        onRetry: () {},
        onDismiss: () {},
        messageKey: const ValueKey('message'),
      ),
    );

    expect(find.text('Retry'), findsNothing);
    expect(find.text('Dismiss'), findsOneWidget);
    final text =
        (find.byKey(const ValueKey('message')).evaluate().single.widget as Text)
            .data!;
    expect(text, contains('Change it and save again.'));
  });

  testWidgets('the verb in the message follows `what`', (tester) async {
    await _pump(
      tester,
      SaveFailedBanner(
        message: 'x',
        what: 'create the table',
        retryable: true,
        onRetry: () {},
        onDismiss: () {},
        messageKey: const ValueKey('message'),
      ),
    );

    final text =
        (find.byKey(const ValueKey('message')).evaluate().single.widget as Text)
            .data!;
    expect(text, startsWith("Couldn't create the table."));
  });

  group('confirmDiscard', () {
    Future<bool?> ask(WidgetTester tester, String tap, {String? title}) async {
      bool? result;
      await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = title == null
                ? await confirmDiscard(context)
                : await confirmDiscard(context, title: title),
            child: const Text('go'),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      if (title != null) {
        expect(find.text(title), findsOneWidget);
      }
      await tester.tap(find.text(tap));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('Discard returns true', (tester) async {
      expect(await ask(tester, 'Discard'), isTrue);
    });

    testWidgets('Keep editing returns false', (tester) async {
      expect(await ask(tester, 'Keep editing'), isFalse);
    });

    testWidgets('the copy is the caller\'s', (tester) async {
      expect(await ask(tester, 'Keep editing', title: 'Leave?'), isFalse);
    });
  });

  group('loadFailedView', () {
    Future<void> show(WidgetTester tester, Object error) => _pump(
      tester,
      loadFailedView(
        error,
        title: 'Things could not be loaded.',
        onRetry: () {},
      ),
    );

    testWidgets('an unreachable server offers Retry', (tester) async {
      await show(tester, _http(503));
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('401 and 403 are authorization states without Retry', (
      tester,
    ) async {
      for (final status in [401, 403]) {
        await show(tester, _http(status));
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
      }
    });

    testWidgets('404 is a not-found state without Retry', (tester) async {
      await show(tester, _http(404));
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('a rejected request shows the message without Retry', (
      tester,
    ) async {
      await show(tester, _http(400));
      expect(find.text('Retry'), findsNothing);
      expect(find.text('The request failed (400).'), findsOneWidget);
    });
  });
}
