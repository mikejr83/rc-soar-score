import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/publication_facts.dart';
import 'package:soar_score_contest/widgets/workspace/next_step/next_step_card.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/next_step_support.dart';
import '../../../support/preferences_scope.dart';

void main() {
  testWidgets('the next step keeps the contest zone whatever zone is '
      'preferred', (tester) async {
    final step = stepAt(
      stepFacts(
        state: LifecycleState.completed,
        publication: PublicationFacts.fromJson(const {
          'visibility': 'Unlisted',
          'published_at': '2026-10-18T22:40:00.000Z',
        }),
      ),
    );
    await tester.pumpWidget(
      withPreferredZone(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NextStepCard(
                step: step,
                busy: false,
                factsUnavailable: false,
                onRetryFacts: () {},
                onPressed: (_) {},
              ),
            ),
          ),
        ),
        zone: 'Asia/Tokyo',
      ),
    );

    // 22:40 UTC is 16:40 in the fixture contest's zone and 07:40 the next day
    // in Tokyo.
    expect(find.textContaining('Sun Oct 18, 16:40'), findsOneWidget);
    expect(find.textContaining('07:40'), findsNothing);
  });
}
