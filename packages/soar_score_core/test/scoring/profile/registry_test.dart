import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('ScoringProfileRegistry', () {
    test('resolves a registered profile by discipline and version', () {
      final v1 = FakeProfile();
      final v2 = FakeProfile(version: 2);
      final registry = ScoringProfileRegistry([v1, v2]);

      expect(registry.resolve(DisciplineType.f5j, 1), same(v1));
      expect(registry.resolve(DisciplineType.f5j, 2), same(v2));
      expect(registry.profiles, hasLength(2));
    });

    test('rejects an unknown discipline or version', () {
      final registry = ScoringProfileRegistry([FakeProfile()]);

      expect(
        () => registry.resolve(DisciplineType.f3j, 1),
        throwsA(isA<UnknownScoringProfileError>()),
      );
      expect(
        () => registry.resolve(DisciplineType.f5j, 9),
        throwsA(isA<UnknownScoringProfileError>()),
      );
    });

    test('rejects registering the same discipline and version twice', () {
      final registry = ScoringProfileRegistry([FakeProfile()]);

      expect(() => registry.register(FakeProfile()), throwsStateError);
    });
  });

  group('resolveOptions', () {
    final profile = FakeProfile();

    test('returns the defaults without overrides', () {
      expect(profile.resolveOptions(), {'group_score_mode': 'Normalized'});
    });

    test('lays overrides over the defaults', () {
      expect(profile.resolveOptions({'group_score_mode': 'Time'}), {
        'group_score_mode': 'Time',
      });
    });

    test('rejects an override of an unknown option', () {
      expect(
        () => profile.resolveOptions({'nope': 1}),
        throwsA(isA<ScoringValidationError>()),
      );
    });
  });
}
