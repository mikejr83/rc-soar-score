import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

PublicationIdentity make({
  ClaimStatus claim = ClaimStatus.claimed,
  Id? owner,
  String? email,
  int? hiddenThrough,
  DateTime? hiddenAt,
}) => PublicationIdentity(
  id: exampleId(1),
  contestId: exampleId(2),
  ownerPublicProfileId:
      owner ?? (claim == ClaimStatus.claimed ? exampleId(3) : null),
  claimStatus: claim,
  verificationEmail: email,
  resultsHiddenThroughRound: hiddenThrough,
  resultsHiddenAt: hiddenAt,
);

void main() {
  group('PublicationIdentity', () {
    test('round trips with documented enum text', () {
      final p = make();
      final json = p.toJson();
      expect(json['claim_status'], 'Claimed');
      expect(json['visibility'], 'Unlisted');
      expect(p.revision, 0);
      expect(PublicationIdentity.fromJson(json), p);
      expect(p, isA<BackendOnly>());
    });

    test('an owner is set exactly when claimed', () {
      expect(
        () => make(
          claim: ClaimStatus.unclaimed,
          owner: exampleId(3),
          email: 'a@b.c',
        ),
        throwsArgumentError,
      );
      expect(
        () => PublicationIdentity(
          id: exampleId(1),
          claimStatus: ClaimStatus.claimed,
        ),
        throwsArgumentError,
      );
    });

    test('an unclaimed publication is found by its verification email', () {
      expect(() => make(claim: ClaimStatus.unclaimed), throwsArgumentError);
      expect(
        make(claim: ClaimStatus.unclaimed, email: 'a@b.c').verificationEmail,
        'a@b.c',
      );
    });

    test('the contest can be gone', () {
      final p = PublicationIdentity(
        id: exampleId(1),
        ownerPublicProfileId: exampleId(3),
        claimStatus: ClaimStatus.claimed,
        visibility: PublicationVisibility.delisted,
      );
      expect(p.contestId, isNull);
      expect(p.isDelisted, isTrue);
      expect(p.toJson()['visibility'], 'Delisted');
    });

    test('hiding fields are set together, from round 1', () {
      expect(() => make(hiddenThrough: 2), throwsArgumentError);
      expect(() => make(hiddenAt: t0), throwsArgumentError);
      expect(() => make(hiddenThrough: 0, hiddenAt: t0), throwsArgumentError);
      expect(make(hiddenThrough: 2, hiddenAt: t0).resultsHiddenThroughRound, 2);
    });
  });
}
