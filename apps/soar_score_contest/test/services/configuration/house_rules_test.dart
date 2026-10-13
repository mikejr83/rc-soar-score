import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/configuration/house_rules.dart';
import 'package:soar_score_contest/services/configuration/setting_catalog.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/configuration_fixtures.dart';

DisciplineProfileWithRules _f5j() => SystemDisciplineProfiles.all.firstWhere(
  (profile) => profile.profile.id == SystemDisciplineProfiles.f5jId,
);

void main() {
  group('ofRevision', () {
    test('is zero without a revision or a known profile', () {
      expect(HouseRules.ofRevision(null, _f5j()), 0);
      expect(HouseRules.ofRevision(configRevision(1), null), 0);
    });

    test('is zero when the revision stores the official values', () {
      expect(HouseRules.ofRevision(configRevision(1), _f5j()), 0);
    });

    test('counts an option that differs from the official value', () {
      final revision = configRevision(1, discipline: {'working_time': 480});
      expect(HouseRules.ofRevision(revision, _f5j()), 1);
    });

    test('is zero when a stored option equals the official value', () {
      final official = SettingCatalog.forProfile(_f5j()).disciplineSettings
          .firstWhere((def) => def.key.endsWith('working_time'))
          .official;
      final revision = configRevision(
        1,
        discipline: {'working_time': official},
      );
      expect(HouseRules.ofRevision(revision, _f5j()), 0);
    });
  });

  group('isHouseRule', () {
    final catalog = SettingCatalog.forProfile(_f5j());

    test('a setting with no official value is never a house rule', () {
      final plain = catalog.settings.firstWhere((def) => def.official == null);
      expect(HouseRules.isHouseRule(plain, 'anything'), isFalse);
    });

    test('count reads each value with the callback', () {
      final defs = catalog.disciplineSettings.toList();
      expect(defs, isNotEmpty);
      expect(HouseRules.count(defs, (def) => def.official), 0);
    });
  });
}
