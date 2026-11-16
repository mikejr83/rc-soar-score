import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// The demo contest's pending pilot submissions are written on the
/// installation with the director's authority, so the installation's upload
/// of them is accepted like any other change.
void _tests(Backend backend) {
  late AcceptorHarness harness;

  setUp(() async => harness = await AcceptorHarness.open(backend));
  tearDown(() => harness.close());

  test(
    'the server accepts the seeded pending submissions and review',
    () async {
      await DemoDataSeeder(
        harness.clientRepository,
        localAccountId: harness.account,
      ).seed();
      final running =
          (await harness.clientRepository.contestRepository.getAll())
              .firstWhere((c) => c.name == 'Mountain States Team F5J');

      // Throws unless every mutation of both scopes is accepted.
      await harness.uploadAll(running.id);

      final placeholders =
          (await harness.server.stores.of('ScorePlaceholder').all())
              .cast<core.ScorePlaceholder>()
              .where((p) => p.contestId == running.id);
      expect(
        placeholders.where(
          (p) => p.state == core.ScorePlaceholderState.submitted,
        ),
        hasLength(3),
      );
      expect(
        placeholders.where(
          (p) => p.state == core.ScorePlaceholderState.inReview,
        ),
        hasLength(1),
      );
      final attempts = (await harness.server.stores.of('ScoreAttempt').all())
          .cast<core.ScoreAttempt>()
          .where((a) => a.authority == core.Authority.participant);
      expect(attempts, hasLength(4));
      expect(await harness.server.count('review_requests'), 1);
    },
  );
}
