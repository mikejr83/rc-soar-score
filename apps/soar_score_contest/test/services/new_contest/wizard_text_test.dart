import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/date_range_text.dart';
import 'package:soar_score_contest/services/new_contest/time_zones.dart';
import 'package:soar_score_contest/services/new_contest/wizard_discipline.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  test('date ranges are compact', () {
    expect(
      dateRangeText(DateTime(2026, 11, 14), DateTime(2026, 11, 14)),
      'Nov 14, 2026',
    );
    expect(
      dateRangeText(DateTime(2026, 9, 5), DateTime(2026, 9, 6)),
      'Sep 5–6, 2026',
    );
    expect(
      dateRangeText(DateTime(2026, 9, 30), DateTime(2026, 10, 1)),
      'Sep 30 – Oct 1, 2026',
    );
    expect(
      dateRangeText(DateTime(2026, 12, 31), DateTime(2027, 1, 1)),
      'Dec 31, 2026 – Jan 1, 2027',
    );
  });

  test('the device time zone is matched by abbreviation or Windows name', () {
    expect(TimeZones.device('EDT'), 'America/New_York');
    expect(TimeZones.device('Pacific Standard Time'), 'America/Los_Angeles');
    expect(TimeZones.device('XYZ'), TimeZones.utc);
    expect(TimeZones.offered, contains(TimeZones.device()));
  });

  test('only disciplines with a system profile are supported', () {
    expect(WizardDiscipline.values.where((d) => d.supported), [
      WizardDiscipline.ales,
      WizardDiscipline.f3j,
      WizardDiscipline.f5j,
      WizardDiscipline.thermalDuration,
    ]);
    expect(
      WizardDiscipline.forProfile(SystemDisciplineProfiles.thermalId),
      WizardDiscipline.thermalDuration,
    );
  });
}
