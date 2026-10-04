import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

PublicationParticipant make({
  String key = 'p_7Hq2xK',
  Map<String, Object?>? details = const {'name': 'Sam Ortega'},
  Id? profile,
  DateTime? redacted,
}) => PublicationParticipant(
  id: exampleId(1),
  publicationId: exampleId(2),
  pilotKey: key,
  sourceParticipationId: exampleId(3),
  details: details,
  publicProfileId: profile,
  redactedAt: redacted,
  createdAt: t0,
  updatedAt: t0,
);

PublicationParticipant redactedRow() => make(details: null, redacted: t0);

void main() {
  group('PublicationParticipant', () {
    test('round trips and is not private data', () {
      final p = make(profile: exampleId(4));
      expect(PublicationParticipant.fromJson(p.toJson()), p);
      expect(p, isA<BackendOnly>());
      expect(p, isNot(isA<PrivateData>()));
      expect(p.isRedacted, isFalse);
    });

    test('a redacted row has no details and no public profile', () {
      final r = redactedRow();
      expect(r.isRedacted, isTrue);
      expect(r.toJson()['details'], isNull);
      expect(r.toJson()['public_profile_id'], isNull);
      expect(PublicationParticipant.fromJson(r.toJson()), r);
      expect(() => make(redacted: t0), throwsArgumentError);
      expect(
        () => make(details: null, profile: exampleId(4), redacted: t0),
        throwsArgumentError,
      );
    });

    test('needs a pilot key', () {
      expect(() => make(key: ' '), throwsArgumentError);
    });

    test('copies the details', () {
      final d = <String, Object?>{'name': 'A'};
      final p = make(details: d);
      d['name'] = 'B';
      expect(p.details!['name'], 'A');
    });
  });
}
