import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/widgets/publication/publication_text.dart';

import '../../../support/fake_app_connectivity.dart';
import '../../../support/matrix_test_support.dart';
import '../../../support/next_step_widget_support.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

String _current(WidgetTester tester) => tester
    .widget<Text>(_key('control-publication-current'))
    .textSpan!
    .toPlainText();

bool _enabled(WidgetTester tester, String key) {
  final button = tester.widget<ButtonStyleButton>(_key(key));
  return button.onPressed != null;
}

WorkspaceServer _server() => WorkspaceServer(
  state: LifecycleState.completed,
  configuration: matrixConfiguration(),
);

void main() {
  group('the publication card', () {
    testWidgets('an unpublished contest offers Publish', (tester) async {
      await pumpWorkspace(tester, _server());
      expect(_current(tester), contains('Unpublished'));
      expect(find.text('Publish results'), findsWidgets);
      expect(_key('publication-visibility'), findsNothing);
      expect(_key('publication-change-policy'), findsNothing);
    });

    testWidgets('publishing shows the revision, then the result', (
      tester,
    ) async {
      final server = _server();
      await pumpWorkspace(tester, server);
      await tester.ensureVisible(_key('publication-publish'));
      await tester.tap(_key('publication-publish'));
      await tester.pumpAndSettle();
      expect(_key('publish-dialog'), findsOneWidget);
      expect(find.text('Contest revision: 1'), findsOneWidget);
      expect(find.text('Visibility: Unlisted'), findsOneWidget);
      await tester.tap(_key('publish-dialog-confirm'));
      await tester.pumpAndSettle();
      expect(server.publishes, hasLength(1));
      expect(server.publishes.single['source_contest_revision'], 1);
      expect(server.publishes.single['client_mutation_id'], isNotEmpty);
      expect(find.text('Results published.'), findsOneWidget);
      expect(_current(tester), contains('Published, Unlisted'));
      expect(find.text('Publish update'), findsOneWidget);
    });

    testWidgets('cancelling the dialog publishes nothing', (tester) async {
      final server = _server();
      await pumpWorkspace(tester, server);
      await tester.ensureVisible(_key('publication-publish'));
      await tester.tap(_key('publication-publish'));
      await tester.pumpAndSettle();
      await tester.tap(_key('publish-dialog-cancel'));
      await tester.pumpAndSettle();
      expect(server.publishes, isEmpty);
      expect(_current(tester), contains('Unpublished'));
    });

    testWidgets('a published contest shows the policy and a link', (
      tester,
    ) async {
      final server = _server()..startPublished();
      await pumpWorkspace(tester, server);
      expect(_current(tester), contains('Published, Unlisted'));
      expect(find.textContaining('Last published'), findsOneWidget);
      expect(find.textContaining('Public updates:'), findsOneWidget);
      expect(_key('publication-change-policy'), findsOneWidget);
    });

    testWidgets('an update shows the latest projection time', (tester) async {
      final server = _server()..startPublished();
      await pumpWorkspace(tester, server);
      await tester.ensureVisible(_key('publication-publish'));
      await tester.tap(_key('publication-publish'));
      await tester.pumpAndSettle();
      await tester.tap(_key('publish-dialog-confirm'));
      await tester.pumpAndSettle();
      final time = AppLocalizationsEn().publicationTime(
        DateTime.parse('2026-10-17T16:00:00Z'),
      );
      expect(find.textContaining('Last published $time.'), findsOneWidget);
    });

    testWidgets('making it public asks first and then changes it', (
      tester,
    ) async {
      final server = _server()..startPublished();
      await pumpWorkspace(tester, server);
      await tester.ensureVisible(_key('publication-visibility'));
      await tester.tap(_key('publication-visibility'));
      await tester.pumpAndSettle();
      expect(_key('public-dialog'), findsOneWidget);
      await tester.tap(_key('public-dialog-confirm'));
      await tester.pumpAndSettle();
      expect(server.visibilities, ['Public']);
      expect(_current(tester), contains('Published, Public'));
      expect(find.text('Make unlisted'), findsOneWidget);
    });

    testWidgets('making it unlisted needs no confirmation', (tester) async {
      final server = _server()..startPublished(visibility: 'Public');
      await pumpWorkspace(tester, server);
      await tester.ensureVisible(_key('publication-visibility'));
      await tester.tap(_key('publication-visibility'));
      await tester.pumpAndSettle();
      expect(_key('public-dialog'), findsNothing);
      expect(server.visibilities, ['Unlisted']);
      expect(_current(tester), contains('Published, Unlisted'));
    });

    testWidgets('requesting delisting asks first, then shows it pending', (
      tester,
    ) async {
      final server = _server()..startPublished(visibility: 'Public');
      await pumpWorkspace(tester, server);
      expect(_key('publication-withdraw-delisting'), findsNothing);
      await tester.ensureVisible(_key('publication-request-delisting'));
      await tester.tap(_key('publication-request-delisting'));
      await tester.pumpAndSettle();
      expect(_key('delist-dialog'), findsOneWidget);
      expect(find.textContaining('Nothing in the contest becomes'), findsOne);
      await tester.enterText(_key('delist-dialog-reason'), ' Wrong contest ');
      await tester.tap(_key('delist-dialog-confirm'));
      await tester.pumpAndSettle();
      expect(server.delistReasons, ['Wrong contest']);
      expect(find.text('Delisting requested.'), findsOneWidget);
      expect(_current(tester), contains('Delisting requested'));
      expect(_key('publication-request-delisting'), findsNothing);
      expect(_key('publication-withdraw-delisting'), findsOneWidget);
    });

    testWidgets('cancelling the delisting dialog asks for nothing', (
      tester,
    ) async {
      final server = _server()..startPublished(visibility: 'Public');
      await pumpWorkspace(tester, server);
      await tester.ensureVisible(_key('publication-request-delisting'));
      await tester.tap(_key('publication-request-delisting'));
      await tester.pumpAndSettle();
      await tester.tap(_key('delist-dialog-cancel'));
      await tester.pumpAndSettle();
      expect(server.delistReasons, isEmpty);
      expect(_current(tester), isNot(contains('Delisting requested')));
    });

    testWidgets('a pending request shows on the card and can be withdrawn', (
      tester,
    ) async {
      final server = _server()
        ..startPublished(visibility: 'Public')
        ..startDelistPending();
      await pumpWorkspace(tester, server);
      expect(_current(tester), contains('Delisting requested'));
      await tester.ensureVisible(_key('publication-withdraw-delisting'));
      await tester.tap(_key('publication-withdraw-delisting'));
      await tester.pumpAndSettle();
      expect(server.delistWithdrawals, 1);
      expect(find.text('Delisting request withdrawn.'), findsOneWidget);
      expect(_current(tester), isNot(contains('Delisting requested')));
      expect(_key('publication-request-delisting'), findsOneWidget);
    });

    testWidgets('withdrawing a request that is gone says so and refreshes', (
      tester,
    ) async {
      final server = _server()
        ..startPublished(visibility: 'Public')
        ..startDelistPending();
      await pumpWorkspace(tester, server);
      server.delistRequest = null;
      await tester.ensureVisible(_key('publication-withdraw-delisting'));
      await tester.tap(_key('publication-withdraw-delisting'));
      await tester.pumpAndSettle();
      expect(
        find.text('There is no pending delisting request any more.'),
        findsOneWidget,
      );
      expect(_key('publication-request-delisting'), findsOneWidget);
    });

    testWidgets('a refused delisting request is explained', (tester) async {
      final server = _server()
        ..startPublished(visibility: 'Public')
        ..delistRefusal = 409;
      await pumpWorkspace(tester, server);
      await tester.ensureVisible(_key('publication-request-delisting'));
      await tester.tap(_key('publication-request-delisting'));
      await tester.pumpAndSettle();
      await tester.tap(_key('delist-dialog-confirm'));
      await tester.pumpAndSettle();
      expect(
        find.text('This publication was delisted and can no longer change.'),
        findsOneWidget,
      );
    });

    testWidgets('an Unlisted publication cannot be delisted', (tester) async {
      final server = _server()..startPublished();
      await pumpWorkspace(tester, server);
      expect(_key('publication-request-delisting'), findsNothing);
    });

    testWidgets('a server refusal for a non-Public publication is explained', (
      tester,
    ) async {
      final server = _server()
        ..startPublished(visibility: 'Public')
        ..delistRefusal = 409
        ..delistRefusalCode = 'publication_not_public';
      await pumpWorkspace(tester, server);
      await tester.ensureVisible(_key('publication-request-delisting'));
      await tester.tap(_key('publication-request-delisting'));
      await tester.pumpAndSettle();
      await tester.tap(_key('delist-dialog-confirm'));
      await tester.pumpAndSettle();
      expect(
        find.text('Delisting can only be requested for a Public publication.'),
        findsOneWidget,
      );
    });

    testWidgets('unpublished and delisted contests offer no delisting', (
      tester,
    ) async {
      await pumpWorkspace(tester, _server());
      expect(_key('publication-request-delisting'), findsNothing);
    });

    testWidgets('offline disables delisting with the reason', (tester) async {
      final monitor = FakeAppConnectivity()
        ..internetStatus = ConnectivityStatus.unavailable;
      final server = _server()..startPublished(visibility: 'Public');
      await pumpWorkspace(tester, server, monitor: monitor);
      expect(_enabled(tester, 'publication-request-delisting'), isFalse);
      expect(find.text('Needs a connection.'), findsWidgets);
    });

    testWidgets('offline disables withdrawing too', (tester) async {
      final monitor = FakeAppConnectivity()
        ..internetStatus = ConnectivityStatus.unavailable;
      final server = _server()
        ..startPublished()
        ..startDelistPending();
      await pumpWorkspace(tester, server, monitor: monitor);
      expect(_enabled(tester, 'publication-withdraw-delisting'), isFalse);
    });

    testWidgets('a stale contest is explained', (tester) async {
      final server = _server()
        ..publicationRefusal = 409
        ..publicationRefusalCode = 'stale_source_revision';
      await pumpWorkspace(tester, server);
      await tester.ensureVisible(_key('publication-publish'));
      await tester.tap(_key('publication-publish'));
      await tester.pumpAndSettle();
      await tester.tap(_key('publish-dialog-confirm'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('The contest changed since you opened'),
        findsOneWidget,
      );
      expect(_current(tester), contains('Unpublished'));
    });

    testWidgets('offline disables the actions with a reason', (tester) async {
      final monitor = FakeAppConnectivity()
        ..internetStatus = ConnectivityStatus.unavailable;
      await pumpWorkspace(tester, _server(), monitor: monitor);
      expect(_enabled(tester, 'publication-publish'), isFalse);
      expect(_key('control-publication-reason'), findsOneWidget);
      expect(find.text('Needs a connection.'), findsWidgets);
    });

    testWidgets('a server that does not publish says so', (tester) async {
      final server = _server()
        ..publicationStatus = 409
        ..publicationReadCode = 'publishing_not_available';
      await pumpWorkspace(tester, server);
      expect(_current(tester), contains('Not available'));
      expect(_enabled(tester, 'publication-publish'), isFalse);
      expect(
        find.text('This server does not publish contests.'),
        findsOneWidget,
      );
    });

    testWidgets('a failed read is unknown, not unpublished', (tester) async {
      final server = _server()..publicationStatus = 500;
      await pumpWorkspace(tester, server);
      expect(_current(tester), contains('Unknown'));
      expect(_enabled(tester, 'publication-publish'), isFalse);
    });

    testWidgets('opens the Publication page', (tester) async {
      await pumpWorkspace(tester, _server());
      await tester.ensureVisible(_key('publication-open-page'));
      await tester.tap(_key('publication-open-page'));
      await tester.pumpAndSettle();
      expect(find.text('Publication stub'), findsOneWidget);
    });
  });
}
