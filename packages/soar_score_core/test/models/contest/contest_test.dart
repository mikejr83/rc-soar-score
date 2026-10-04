import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('Contest', () {
    test('round trips through JSON with nulls and enum text', () {
      final contest = makeContest(revision: 7);
      final json = contest.toJson();
      expect(json['start_date_time'], '2026-10-17T14:00:00Z');
      expect(json['lifecycle_state'], 'Created');
      expect(json['scoring_access'], 'Closed');
      expect(json['admin_lock'], 'Unlocked');
      expect(json['host'], isNull);
      expect(json['results_hidden_at'], isNull);
      expect(Contest.fromJson(json), contest);
    });

    test('defaults to revision 0 and the initial control states', () {
      final contest = makeContest();
      expect(contest.revision, 0);
      expect(contest.lifecycleState, LifecycleState.created);
      expect(contest.scoringAccess, ScoringAccess.closed);
      expect(contest.adminLock, AdminLock.unlocked);
      expect(contest.localArchive, isFalse);
    });

    test('trims the name and rejects a blank name or timezone', () {
      expect(makeContest(name: '  Open  ').name, 'Open');
      expect(() => makeContest(name: ' '), throwsArgumentError);
      expect(() => makeContest(timezone: ''), throwsArgumentError);
    });

    test('stores every timestamp in UTC', () {
      final contest = makeContest(startDateTime: DateTime(2026, 10, 17, 8));
      expect(contest.startDateTime.isUtc, isTrue);
      expect(contest.createdAt.isUtc, isTrue);
    });

    test('rejects an end before the start and a negative revision', () {
      expect(
        () =>
            makeContest(endDateTime: start.subtract(const Duration(hours: 1))),
        throwsArgumentError,
      );
      expect(() => makeContest(revision: -1), throwsArgumentError);
    });

    test('rejects a non-UTC timestamp on the wire', () {
      expect(
        () => Contest.fromJson({
          ...makeContest().toJson(),
          'start_date_time': '2026-10-17T08:00:00-06:00',
        }),
        throwsFormatException,
      );
    });

    test('is synchronized contest data with an identity', () {
      final contest = makeContest(revision: 3);
      expect(contest, isA<Synchronizable>());
      expect(contest.syncScope, SyncScope.contest);
      expect(contest.entityType, 'Contest');
      expect(contest.revision, 3);
    });

    test('compares by value', () {
      expect(makeContest(), makeContest());
      expect(makeContest(), isNot(makeContest(name: 'Other')));
      expect(makeContest().hashCode, makeContest().hashCode);
    });
  });
}
