import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'ids.dart';

DisciplineProfile make({
  int version = 1,
  ProfileStatus status = ProfileStatus.published,
  Id? supersededBy,
}) => DisciplineProfile(
  id: exampleId(1),
  type: DisciplineType.ales,
  version: version,
  name: 'ALES',
  category: DisciplineCategory.duration,
  status: status,
  supersededBy: supersededBy,
  createdBy: exampleId(2),
  createdAt: t0,
);

void main() {
  group('DisciplineProfile', () {
    test('round trips with the documented enum text', () {
      final profile = make();
      final json = profile.toJson();
      expect(json['type'], 'ALES');
      expect(json['category'], 'duration');
      expect(json['status'], 'published');
      expect(DisciplineProfile.fromJson(json), profile);
    });

    test('is system scoped', () {
      expect(make().syncScope, SyncScope.system);
    });

    test('version starts at 1', () {
      expect(() => make(version: 0), throwsArgumentError);
    });

    test('superseded_by is set exactly when superseded', () {
      expect(() => make(status: ProfileStatus.superseded), throwsArgumentError);
      expect(() => make(supersededBy: exampleId(9)), throwsArgumentError);
      final ok = make(
        status: ProfileStatus.superseded,
        supersededBy: exampleId(9),
      );
      expect(ok.supersededBy, exampleId(9));
    });

    test('discipline types use their documented text', () {
      const text = {
        DisciplineType.ales: 'ALES',
        DisciplineType.thermalDuration: 'ThermalDuration',
        DisciplineType.f3j: 'F3J',
        DisciplineType.f5j: 'F5J',
        DisciplineType.f3l: 'F3L',
        DisciplineType.f3k: 'F3K',
      };
      for (final entry in text.entries) {
        final json = make().toJson()..['type'] = entry.value;
        expect(DisciplineProfile.fromJson(json).type, entry.key);
      }
    });
  });
}
