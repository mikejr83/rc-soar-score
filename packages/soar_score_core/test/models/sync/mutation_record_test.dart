import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'ids.dart';

MutationRecord make({
  Id? contest,
  Id? owner,
  int? sequence,
  MutationOutcome outcome = MutationOutcome.pending,
  int? baseRevision,
  Map<String, Object?>? payload,
}) => MutationRecord(
  id: exampleId(0xc3),
  contestId: contest,
  ownerAccountId: owner,
  sequence: sequence,
  entityType: 'ScoreAttempt',
  entityId: exampleId(0x401),
  baseRevision: baseRevision,
  clientMutationId: '01J9ZM5B2E4G6H8K0N2Q4S6U8W',
  authority: Authority.director,
  clientTime: t0,
  payload: payload ?? {'a': 1},
  outcome: outcome,
);

void main() {
  final contest = exampleId(0x10);

  group('MutationRecord', () {
    test('round trips through JSON, keeping nulls and nested payload', () {
      final record = make(
        contest: contest,
        sequence: 405,
        outcome: MutationOutcome.accepted,
        payload: {
          'raw_components': {'time_flown': 585},
        },
      );
      final json = record.toJson();
      expect(json['outcome'], 'Accepted');
      expect(json['authority'], 'Director');
      expect(json['owner_account_id'], isNull);
      expect(json['server_rejection_time'], isNull);
      expect(MutationRecord.fromJson(json), record);
    });

    test('defaults to Pending with no sequence', () {
      final record = make(contest: contest);
      expect(record.outcome, MutationOutcome.pending);
      expect(record.sequence, isNull);
    });

    test('needs exactly one of contest and owner', () {
      expect(() => make(), throwsArgumentError);
      expect(
        () => make(contest: contest, owner: exampleId(1)),
        throwsArgumentError,
      );
    });

    test('sets a sequence only on an accepted change', () {
      expect(() => make(contest: contest, sequence: 1), throwsArgumentError);
      expect(
        make(
          contest: contest,
          sequence: 1,
          outcome: MutationOutcome.accepted,
        ).sequence,
        1,
      );
    });

    test('rejects a negative base revision and blank identifiers', () {
      expect(
        () => make(contest: contest, baseRevision: -1),
        throwsArgumentError,
      );
      expect(
        () => MutationRecord(
          id: exampleId(1),
          contestId: contest,
          entityType: ' ',
          entityId: exampleId(2),
          clientMutationId: 'x',
          authority: Authority.system,
          clientTime: t0,
          payload: const {},
        ),
        throwsArgumentError,
      );
    });

    test('copies the payload so later edits do not leak in', () {
      final source = <String, Object?>{'a': 1};
      final record = make(contest: contest, payload: source);
      source['a'] = 2;
      expect(record.payload['a'], 1);
      expect(() => record.payload['b'] = 1, throwsUnsupportedError);
    });

    test('scope follows the owner of the data', () {
      expect(make(contest: contest).syncScope, SyncScope.contest);
      expect(make(owner: exampleId(1)).syncScope, SyncScope.director);
    });

    test('outcome and authority values match the documents', () {
      const outcomes = {
        'Pending': MutationOutcome.pending,
        'Accepted': MutationOutcome.accepted,
        'Rejected': MutationOutcome.rejected,
        'Conflict': MutationOutcome.conflict,
        'Skipped': MutationOutcome.skipped,
      };
      const authorities = {
        'Director': Authority.director,
        'Participant': Authority.participant,
        'Helper': Authority.helper,
        'System': Authority.system,
        'Administrator': Authority.administrator,
      };
      final base = make(contest: contest).toJson();
      for (final e in outcomes.entries) {
        expect(
          MutationRecord.fromJson({...base, 'outcome': e.key}).outcome,
          e.value,
        );
      }
      for (final e in authorities.entries) {
        expect(
          MutationRecord.fromJson({...base, 'authority': e.key}).authority,
          e.value,
        );
      }
    });
  });
}
