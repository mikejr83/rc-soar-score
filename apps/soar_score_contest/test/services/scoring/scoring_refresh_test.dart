import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/scoring/scoring_controller.dart';
import 'package:soar_score_contest/widgets/scoring/scoring_refresh_failed_banner.dart';

import '../../support/matrix_test_support.dart';
import '../../support/scoring_test_support.dart';

void main() {
  test('a refresh that works again clears the earlier failure', () async {
    final server = ScoringServer();
    final c = ScoringController(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(server.handle),
      ),
      contestId: contestId,
    );
    addTearDown(c.dispose);
    await c.load();
    expect(c.data, isNotNull);

    server.readFailure = 503;
    await c.refresh();
    expect(c.loadError, isNotNull);
    expect(c.data, isNotNull, reason: 'the scores stay usable');

    server.readFailure = null;
    await c.refresh();
    expect(c.loadError, isNull);
  });

  group('ScoringRefreshFailedBanner', () {
    Future<void> pump(WidgetTester tester, int status) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoringRefreshFailedBanner(
              error: ApiHttpError(
                'failed',
                statusCode: status,
                body:
                    '{"error":{"code":"${status == 403 ? 'forbidden' : 'internal_error'}",'
                    '"message":"Not available."}}',
                requestUri: Uri.parse('http://localhost/x'),
              ),
              onRetry: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('a server that is down offers Retry', (tester) async {
      await pump(tester, 503);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('a refused account has no Retry', (tester) async {
      await pump(tester, 403);
      expect(
        find.byKey(const ValueKey('scoring-refresh-failed')),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsNothing);
    });
  });
}
