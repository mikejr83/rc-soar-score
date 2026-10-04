import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  group('ScoringUuid', () {
    test('accepts a v4 uuid and normalizes case', () {
      final u = ScoringUuid.parse(' 3F6A1C52-8B7E-4D2A-9C41-0E5D7A9B8F13 ');
      expect(u.value, '3f6a1c52-8b7e-4d2a-9c41-0e5d7a9b8f13');
      expect(u, ScoringUuid.parse(u.value));
    });

    test('rejects a v7 uuid', () {
      expect(
        () => ScoringUuid.parse(Id.create().value),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('UTC timestamps', () {
    test('parses Z and +00:00', () {
      expect(parseUtcTimestamp('2026-04-15T10:30:00Z').isUtc, isTrue);
      expect(parseUtcTimestamp('2026-04-15T10:30:00+00:00').isUtc, isTrue);
    });

    test('rejects other offsets, local times and garbage', () {
      expect(
        () => parseUtcTimestamp('2026-04-15T10:30:00-05:00'),
        throwsFormatException,
      );
      expect(
        () => parseUtcTimestamp('2026-04-15T10:30:00'),
        throwsFormatException,
      );
      expect(() => parseUtcTimestamp('nope'), throwsFormatException);
    });

    test('formats in UTC', () {
      expect(
        formatUtcTimestamp(DateTime.utc(2026, 4, 15, 10, 30)),
        '2026-04-15T10:30:00.000Z',
      );
    });
  });

  group('converters', () {
    test('round trip', () {
      final id = Id.create();
      expect(const IdConverter().fromJson(const IdConverter().toJson(id)), id);
      final t = DateTime.utc(2026, 1, 2, 3, 4, 5);
      const c = UtcTimestampConverter();
      expect(c.fromJson(c.toJson(t)), t);
      final u = ScoringUuid.parse('3f6a1c52-8b7e-4d2a-9c41-0e5d7a9b8f13');
      const s = ScoringUuidConverter();
      expect(s.fromJson(s.toJson(u)), u);
    });
  });

  group('VersionedPayload', () {
    test('round trips and is unmodifiable', () {
      final p = VersionedPayload(version: 2, data: {'a': 1});
      expect(VersionedPayload.fromJson(p.toJson()), p);
      expect(() => p.data['b'] = 2, throwsUnsupportedError);
    });

    test('rejects a version below 1 and malformed json', () {
      expect(
        () => VersionedPayload(version: 0, data: {}),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => VersionedPayload.fromJson({'version': 'x'}),
        throwsFormatException,
      );
    });

    test('registry picks the decoder by entity type and version', () {
      final r = PayloadDecoderRegistry()
        ..register('Team', 1, (d) => 'v1:${d['n']}')
        ..register('Team', 2, (d) => 'v2:${d['n']}');
      expect(
        r.decode('Team', VersionedPayload(version: 1, data: {'n': 'a'})),
        'v1:a',
      );
      expect(
        r.decode('Team', VersionedPayload(version: 2, data: {'n': 'a'})),
        'v2:a',
      );
      expect(
        () => r.decode('Team', VersionedPayload(version: 3, data: {})),
        throwsUnsupportedError,
      );
      expect(() => r.register('Team', 1, (d) => d), throwsStateError);
    });
  });

  test('SyncScope lists the six README scopes', () {
    expect(SyncScope.values.map((s) => s.name), [
      'contest',
      'director',
      'system',
      'issued',
      'derived',
      'backendOnly',
    ]);
  });
}
