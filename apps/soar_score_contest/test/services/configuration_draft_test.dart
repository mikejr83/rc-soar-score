import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/configuration/config_phase.dart';
import 'package:soar_score_contest/services/configuration/configuration_draft.dart';
import 'package:soar_score_contest/services/configuration/configuration_values.dart';
import 'package:soar_score_contest/services/configuration/setting_catalog.dart';
import 'package:soar_score_contest/services/configuration/setting_keys.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/configuration_fixtures.dart';

ConfigurationDraft _draft({
  Map<String, Object?> core = const {},
  Map<String, Object?> discipline = const {},
  ConfigPhase phase = ConfigPhase.before,
  int? lastDrawnRound,
}) => ConfigurationDraft.fromSaved(
  contest: configContest(),
  revision: configRevision(1, core: core, discipline: discipline),
  catalog: SettingCatalog.forProfile(SystemDisciplineProfiles.f5j),
  phase: phase,
  lastDrawnRound: lastDrawnRound,
);

void main() {
  test('a fresh draft has no changes and no errors', () {
    final draft = _draft();
    expect(draft.dirty, isFalse);
    expect(draft.errors, isEmpty);
  });

  test('discipline options start at the profile defaults', () {
    final draft = _draft();
    expect(draft['d_working_time'], 600);
    expect(draft['d_motor_restart_mode'], 'allowed');
  });

  test('a changed value is listed once, in page order', () {
    final draft = _draft()
      ..set(SettingKeys.decimalPlaces, 2)
      ..set(SettingKeys.name, 'Renamed');
    expect(
      [for (final c in draft.changes) c.def.key],
      [SettingKeys.name, SettingKeys.decimalPlaces],
    );
    draft.set(SettingKeys.name, 'Front Range F5J Open');
    expect(draft.changes.single.def.key, SettingKeys.decimalPlaces);
  });

  test('minutes and seconds equal the stored seconds', () {
    final draft = _draft()..set('d_working_time', '10:00');
    expect(draft.dirty, isFalse);
    draft.set('d_working_time', '9:30');
    expect(draft.errors, isEmpty);
    expect(draft.changes.single.def.key, 'd_working_time');
  });

  test('a time with more than 59 seconds is an error', () {
    final draft = _draft()..set('d_working_time', '10:75');
    expect(draft.errors['d_working_time'], contains('Seconds go up to 59'));
  });

  test('a bare number counts as minutes', () {
    final draft = _draft()..set('d_working_time', '8');
    expect(draft.errors, isEmpty);
    final saved = ConfigurationValues.toSave(draft, configRevision(1));
    expect(saved.config.discipline['working_time'], 480);
  });

  test('a blank contest name is an error', () {
    final draft = _draft()..set(SettingKeys.name, ' ');
    expect(draft.errors[SettingKeys.name], 'Enter a contest name.');
  });

  test('the end date cannot be before the start date', () {
    final draft = _draft()..set(SettingKeys.end, '2026-10-01');
    expect(draft.errors[SettingKeys.end], contains('before the start date'));
  });

  test('turning teams on requires how many pilot scores count', () {
    final draft = _draft()..set(SettingKeys.teams, true);
    expect(draft.errors[SettingKeys.teamPilotCount], contains('1 or more'));
    draft.set(SettingKeys.teamPilotCount, '3');
    expect(draft.errors, isEmpty);
  });

  test('team options leave the saved core when teams are off', () {
    final draft = _draft(core: {'teams_enabled': true, 'team_pilot_count': 3})
      ..set(SettingKeys.teams, false);
    expect(draft.changeOf(SettingKeys.teamPilotCount)?.cleared, isTrue);
    final core = ConfigurationValues.toSave(
      draft,
      configRevision(1, core: {'teams_enabled': true, 'team_pilot_count': 3}),
    ).config.core;
    expect(core.containsKey('team_pilot_count'), isFalse);
    expect(core['teams_enabled'], false);
    expect(() => CoreOptions.fromMap(core), returnsNormally);
  });

  test('a second drop must be later than the first', () {
    final draft = _draft()
      ..setAll({
        SettingKeys.drops: 2,
        SettingKeys.drop1: '4',
        SettingKeys.drop2: '3',
      });
    expect(draft.errors[SettingKeys.drop2], contains('later than the first'));
    draft.set(SettingKeys.drop2, '8');
    expect(draft.errors, isEmpty);
    final core = ConfigurationValues.toSave(
      draft,
      configRevision(1),
    ).config.core;
    expect(core['drop_after_rounds'], [4, 8]);
  });

  test('drops cannot come after the last drawn round', () {
    final draft = _draft(phase: ConfigPhase.drawn, lastDrawnRound: 4)
      ..setAll({SettingKeys.drops: 1, SettingKeys.drop1: '6'});
    expect(draft.errors[SettingKeys.drop1], contains('round 4'));
  });

  test('intended total rounds must exceed the preliminary rounds', () {
    final draft = _draft()
      ..setAll({
        SettingKeys.drawMode: SettingKeys.seeded,
        SettingKeys.preliminaryRounds: '3',
        SettingKeys.intendedTotalRounds: '2',
      });
    expect(
      draft.errors[SettingKeys.intendedTotalRounds],
      contains('more than the 3 preliminary rounds'),
    );
  });

  test('a structural change after the draw outdates the matrix', () {
    final draft = _draft(phase: ConfigPhase.drawn)
      ..set(SettingKeys.laneMode, 'Random');
    expect(draft.matrixChanges.single.def.key, SettingKeys.laneMode);
    expect(draft.recalcChanges, isEmpty);
  });

  test('back-to-back flights start on, outdate the matrix and are saved', () {
    final draft = _draft(phase: ConfigPhase.drawn);
    expect(draft[SettingKeys.allowBackToBack], isTrue);

    draft.set(SettingKeys.allowBackToBack, false);

    expect(draft.matrixChanges.single.def.key, SettingKeys.allowBackToBack);
    final saved = ConfigurationValues.toSave(draft, configRevision(1));
    expect(CoreOptions.fromMap(saved.config.core).allowBackToBack, isFalse);
  });

  test('a scoring change while running recalculates, structure is fixed', () {
    final draft = _draft(phase: ConfigPhase.running)
      ..set(SettingKeys.decimalPlaces, 2);
    expect(draft.recalcChanges.single.def.key, SettingKeys.decimalPlaces);
    final lanes = draft.catalog.byKey[SettingKeys.laneMode]!;
    expect(draft.effectOf(lanes).fixed, isTrue);
    expect(
      draft.effectOf(draft.catalog.byKey['d_working_time']!).fixed,
      isTrue,
    );
  });

  test('details are not revisioned and stay editable while running', () {
    final draft = _draft(phase: ConfigPhase.running);
    expect(
      draft.effectOf(draft.catalog.byKey[SettingKeys.name]!).fixed,
      isFalse,
    );
  });

  test('saving builds the core options the server accepts', () {
    final draft = _draft()
      ..setAll({
        SettingKeys.teams: true,
        SettingKeys.teamPilotCount: '3',
        SettingKeys.teamProtection: true,
        SettingKeys.laneMode: 'Random',
      });
    final saved = ConfigurationValues.toSave(draft, configRevision(1));
    final options = CoreOptions.fromMap(saved.config.core);
    expect(options.teamsEnabled, isTrue);
    expect(options.teamPilotCount, 3);
    expect(options.teamProtection, isTrue);
    expect(options.laneMode, LaneMode.random);
    expect(saved.landingTableId, f5jLandingTableId);
  });

  test('only changed details are sent to the contest', () {
    final draft = _draft()..set(SettingKeys.city, 'Boulder');
    expect(draft.detailsChanged, isTrue);
    expect(draft.configurationChanged, isFalse);
    final request = ConfigurationValues.toUpdate(draft, configContest());
    expect(request.city, 'Boulder');
    expect(request.startDateTime, configContest().startDateTime);
  });

  test('choosing another landing table is a change', () {
    final draft = _draft()
      ..set(SettingKeys.landingTable, clubLandingTableId.value);
    expect(draft.changes.single.def.key, SettingKeys.landingTable);
    expect(
      ConfigurationValues.toSave(draft, configRevision(1)).landingTableId,
      clubLandingTableId,
    );
  });

  test('discard puts the saved values back', () {
    final draft = _draft()..set(SettingKeys.decimalPlaces, 3);
    draft.discard();
    expect(draft.dirty, isFalse);
  });
}
