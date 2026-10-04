import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'ids.dart';

AuditEvent make({
  Id? contest,
  Id? owner,
  Id? publication,
  AuditAction action = AuditAction.scoreAttempt,
}) => AuditEvent(
  id: exampleId(0xc6),
  entityType: 'ScoreAttempt',
  entityId: exampleId(0x401),
  contestId: contest,
  ownerAccountId: owner,
  publicationId: publication,
  action: action,
  authority: Authority.director,
  baseRevision: 0,
  resultingRevision: 1,
  serverTimestamp: t0,
);

void main() {
  group('AuditEvent', () {
    test('round trips through JSON with nulls kept', () {
      final event = make(contest: exampleId(0x10));
      final json = event.toJson();
      expect(json['action'], 'ScoreAttempt');
      expect(json['outcome'], 'Success');
      expect(json['publication_id'], isNull);
      expect(json['base_revision'], 0);
      expect(AuditEvent.fromJson(json), event);
    });

    test('allows at most one scope', () {
      expect(make(), isA<AuditEvent>());
      expect(
        () => make(contest: exampleId(1), owner: exampleId(2)),
        throwsArgumentError,
      );
      expect(
        () => make(contest: exampleId(1), publication: exampleId(2)),
        throwsArgumentError,
      );
    });

    test('scope follows the data the event concerns', () {
      expect(make(contest: exampleId(1)).syncScope, SyncScope.contest);
      expect(make(owner: exampleId(1)).syncScope, SyncScope.director);
      expect(make(publication: exampleId(1)).syncScope, SyncScope.backendOnly);
      expect(make().syncScope, SyncScope.backendOnly);
    });

    test('action values match the documents', () {
      const texts = [
        'StateTransition',
        'ScoreAttempt',
        'ScoreReview',
        'InvitationIssued',
        'InvitationReplaced',
        'InvitationRevoked',
        'InvitationDeliveryRequested',
        'InvitationAccessed',
        'InvitationAccessFailed',
        'PublicationAttempt',
        'DelistRequested',
        'DelistDecided',
        'DelistWithdrawn',
        'Redaction',
        'Conflict',
        'ConflictAccepted',
        'ConflictRejected',
        'Deletion',
        'Restoration',
        'InstallationActivation',
      ];
      expect(AuditAction.values, hasLength(texts.length));
      final base = make(contest: exampleId(1)).toJson();
      for (final (i, text) in texts.indexed) {
        final event = AuditEvent.fromJson({...base, 'action': text});
        expect(event.action, AuditAction.values[i]);
        expect(event.toJson()['action'], text);
      }
    });

    test('outcome values match the documents', () {
      final base = make(contest: exampleId(1)).toJson();
      for (final (text, outcome) in [
        ('Success', AuditOutcome.success),
        ('Rejected', AuditOutcome.rejected),
        ('Conflict', AuditOutcome.conflict),
      ]) {
        expect(
          AuditEvent.fromJson({...base, 'outcome': text}).outcome,
          outcome,
        );
      }
    });
  });
}
