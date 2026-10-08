import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/configuration/config_impact.dart';
import 'package:soar_score_contest/services/configuration/configuration_draft.dart';
import 'package:soar_score_core/soar_score_core.dart';

ConfigurationDraft _draft() => ConfigurationDraft(
  ContestConfig(
    core: {'lane_mode': 'None', 'rounding_mode': 'Round'},
    discipline: {},
  ),
);

void main() {
  test('an untouched draft has no changes', () {
    final draft = _draft();
    expect(draft.changed, isFalse);
    expect(draft.impact, ConfigImpact.none);
  });

  test('the impact is the widest among the changed options', () {
    final draft = _draft();
    draft['classes_enabled'] = true;
    expect(draft.impact, ConfigImpact.none);
    draft['rounding_mode'] = 'Truncate';
    expect(draft.impact, ConfigImpact.scores);
    draft['lane_mode'] = 'Fixed';
    expect(draft.impact, ConfigImpact.matrix);
    expect(draft.changedKeys, {
      'classes_enabled',
      'rounding_mode',
      'lane_mode',
    });
  });

  test('setting an option back to its saved value clears the change', () {
    final draft = _draft();
    draft['rounding_mode'] = 'Truncate';
    draft['rounding_mode'] = 'Round';
    expect(draft.changed, isFalse);
  });

  test('invalid options are reported and valid ones are not', () {
    final draft = _draft();
    expect(draft.problem, isNull);
    draft['decimal_places'] = 9;
    expect(draft.problem, isNotNull);
  });

  test('build keeps the discipline settings', () {
    final base = ContestConfig(core: {}, discipline: {'x': 1});
    final draft = ConfigurationDraft(base);
    draft['classes_enabled'] = true;
    expect(draft.build().discipline, {'x': 1});
    expect(draft.build().core['classes_enabled'], true);
  });
}
