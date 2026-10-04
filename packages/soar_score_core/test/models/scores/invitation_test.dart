import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

Invitation make({
  InvitationState state = InvitationState.active,
  int revision = 1,
  DateTime? expires,
  DateTime? first,
  DateTime? last,
  DateTime? revoked,
  Id? replaces,
  String mutationId = '01J9ZK3Q8V7N2M4R6T8W0Y1A3C',
}) => Invitation(
  id: exampleId(1),
  contestId: exampleId(2),
  contestParticipationId: exampleId(3),
  protectedCredential: ProtectedCredential(
    'pbkdf2-sha256\$600000\$c2FsdA\$Zm9v',
  ),
  invitationRevision: revision,
  state: state,
  issuedBy: exampleId(4),
  issuedAt: t0,
  expiresAt: expires,
  firstUsedAt: first,
  lastUsedAt: last,
  revokedAt: revoked,
  replacesInvitationId: replaces,
  deliveryOutcomes: const [
    {'channel': 'print', 'result': 'printed'},
  ],
  clientMutationId: mutationId,
);

void main() {
  group('Invitation', () {
    test('defaults to an active magic link for a pilot', () {
      final i = make();
      expect(i.type, InvitationType.magicUrl);
      expect(i.audience, InvitationAudience.pilot);
      expect(i.isActive, isTrue);
      expect(i.invitationRevision, 1);
      expect(i.syncScope, SyncScope.issued);
    });

    test('the sync form round trips and carries the credential', () {
      final i = make();
      final json = i.toSyncJson();
      expect(json['protected_credential'], startsWith('pbkdf2-sha256'));
      expect(json['type'], 'MagicURL');
      expect(json['state'], 'Active');
      expect(json['audience'], 'Pilot');
      expect(Invitation.fromJson(json), i);
    });

    test('the plain JSON leaves the credential out', () {
      expect(make().toJson().containsKey('protected_credential'), isFalse);
      expect(make().toJson()['client_mutation_id'], isNotEmpty);
    });

    test('the credential never shows in text output', () {
      final c = ProtectedCredential('secret-hash');
      expect(c.toString(), isNot(contains('secret-hash')));
      expect('${make()}', isNot(contains('pbkdf2')));
      expect(() => ProtectedCredential(' '), throwsArgumentError);
    });

    test('type and state values use their documented text', () {
      final json = make().toSyncJson()
        ..['type'] = 'QRCode'
        ..['state'] = 'Expired'
        ..['audience'] = 'Helper';
      final i = Invitation.fromJson(json);
      expect(i.type, InvitationType.qrCode);
      expect(i.state, InvitationState.expired);
      expect(i.audience, InvitationAudience.helper);
    });

    test('a revoked invitation records when', () {
      expect(() => make(state: InvitationState.revoked), throwsArgumentError);
      expect(
        make(state: InvitationState.revoked, revoked: t0).isActive,
        isFalse,
      );
    });

    test('revision starts at 1 and an invitation cannot replace itself', () {
      expect(() => make(revision: 0), throwsArgumentError);
      expect(() => make(replaces: exampleId(1)), throwsArgumentError);
    });

    test('expiry follows issue and last use needs first use', () {
      expect(
        () => make(expires: t0.subtract(const Duration(hours: 1))),
        throwsArgumentError,
      );
      expect(() => make(last: t0), throwsArgumentError);
      expect(make(first: t0, last: t0).lastUsedAt, t0);
    });

    test('needs an idempotency key', () {
      expect(() => make(mutationId: ' '), throwsArgumentError);
    });
  });
}
