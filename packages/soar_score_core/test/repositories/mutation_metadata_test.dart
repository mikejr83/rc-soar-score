import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../models/sync/ids.dart';

void main() {
  group('MutationMetadata.forPart', () {
    final metadata = MutationMetadata(
      clientMutationId: 'request-1',
      authority: Authority.director,
      clientTime: DateTime.utc(2026, 5, 1),
      actorId: exampleId(1),
      sourceDevice: 'laptop',
    );

    test('adds the part to the request id and keeps everything else', () {
      final part = metadata.forPart('team-membership-7');

      expect(part.clientMutationId, 'request-1/team-membership-7');
      expect(part.authority, metadata.authority);
      expect(part.clientTime, metadata.clientTime);
      expect(part.actorId, metadata.actorId);
      expect(part.sourceDevice, 'laptop');
    });

    test('derives the same id every time, and different ids per part', () {
      expect(metadata.forPart('a'), metadata.forPart('a'));
      expect(metadata.forPart('a'), isNot(metadata.forPart('b')));
    });
  });
}
