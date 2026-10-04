import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'ids.dart';

Installation make({String label = 'Field laptop', int seq = 128}) =>
    Installation(
      id: exampleId(0xc0),
      ownerAccountId: exampleId(1),
      label: label,
      platform: Platform.windows,
      createdAt: t0,
      systemDataSeq: seq,
    );

void main() {
  group('Installation', () {
    test('round trips through JSON with nulls kept', () {
      final json = make().toJson();
      expect(json['platform'], 'Windows');
      expect(json['last_seen_at'], isNull);
      expect(json.containsKey('revoked_at'), isTrue);
      expect(json['created_at'], '2026-10-17T15:10:00Z');
      expect(Installation.fromJson(json), make());
    });

    test('is backend only and has no sync scope', () {
      expect(make(), isA<BackendOnly>());
      expect(make(), isNot(isA<SyncScoped>()));
    });

    test('trims the label and rejects a blank one', () {
      expect(make(label: '  Desk  ').label, 'Desk');
      expect(() => make(label: ' '), throwsArgumentError);
    });

    test('rejects a negative system data sequence', () {
      expect(() => make(seq: -1), throwsArgumentError);
    });

    test('reports revocation', () {
      final revoked = Installation.fromJson({
        ...make().toJson(),
        'revoked_at': '2026-10-18T00:00:00Z',
      });
      expect(revoked.isRevoked, isTrue);
      expect(make().isRevoked, isFalse);
    });

    test('rejects a non-UTC timestamp', () {
      expect(
        () => Installation.fromJson({
          ...make().toJson(),
          'created_at': '2026-10-17T10:10:00-05:00',
        }),
        throwsFormatException,
      );
    });

    test('platform values match the documents', () {
      expect(
        Platform.values.map(
          (p) => Installation.fromJson({
            ...make().toJson(),
            'platform': ['Web', 'Windows', 'Other'][p.index],
          }).platform,
        ),
        Platform.values,
      );
    });
  });
}
