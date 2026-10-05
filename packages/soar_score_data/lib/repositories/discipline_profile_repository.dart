import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Discipline profiles and their child rows in the database.
class DisciplineProfileRepository extends DriftRepository
    implements core.DisciplineProfileRepository {
  DisciplineProfileRepository(super.db, {super.stores});

  late final _profiles = store<core.DisciplineProfile>('DisciplineProfile');
  late final _configFields = store<core.DisciplineConfigField>(
    'DisciplineConfigField',
  );
  late final _scoreFields = store<core.DisciplineScoreField>(
    'DisciplineScoreField',
  );
  late final _validations = store<core.DisciplineValidation>(
    'DisciplineValidation',
  );
  late final _formulas = store<core.DisciplineFormula>('DisciplineFormula');
  late final _rules = store<core.DisciplineRule>('DisciplineRule');
  late final _landingTables = store<core.LandingTable>('LandingTable');

  @override
  Future<core.DisciplineProfileWithRules?> findById(core.Id id) async {
    final profile = await _profiles.find(id);
    return profile == null ? null : _withRules(profile);
  }

  @override
  Future<List<core.DisciplineProfileWithRules>> listPublished() async {
    final profiles = [
      for (final profile in await _profiles.all(orderBy: 'type, version, id'))
        if (profile.status == core.ProfileStatus.published) profile,
    ];
    return [for (final profile in profiles) await _withRules(profile)];
  }

  @override
  Future<bool> installSystemProfile(core.DisciplineProfileWithRules profile) =>
      db.transaction(() async {
        final head = profile.profile;
        if (await _profiles.findJson(head.id) != null) return false;
        final tableId = head.defaultLandingTableId;
        if (tableId != null && await _landingTables.findJson(tableId) == null) {
          throw StateError(
            'The default landing table ${tableId.value} of ${head.name} is '
            'not installed; install the landing tables first.',
          );
        }
        await _profiles.upsertJson(_profiles.encode(head));
        for (final row in profile.configFields) {
          await _configFields.upsertJson(_configFields.encode(row));
        }
        for (final row in profile.scoreFields) {
          await _scoreFields.upsertJson(_scoreFields.encode(row));
        }
        for (final row in profile.validations) {
          await _validations.upsertJson(_validations.encode(row));
        }
        for (final row in profile.formulas) {
          await _formulas.upsertJson(_formulas.encode(row));
        }
        for (final row in profile.rules) {
          await _rules.upsertJson(_rules.encode(row));
        }
        return true;
      });

  Future<core.DisciplineProfileWithRules> _withRules(
    core.DisciplineProfile profile,
  ) async => core.DisciplineProfileWithRules(
    profile: profile,
    configFields: await _configFields.whereId(
      'discipline_profile_id',
      profile.id,
      orderBy: 'display_order, id',
    ),
    scoreFields: await _scoreFields.whereId(
      'discipline_profile_id',
      profile.id,
      orderBy: 'display_order, id',
    ),
    validations: await _validations.whereId(
      'discipline_profile_id',
      profile.id,
      orderBy: 'display_order, id',
    ),
    formulas: await _formulas.whereId(
      'discipline_profile_id',
      profile.id,
      orderBy: 'display_order, id',
    ),
    rules: await _rules.whereId(
      'discipline_profile_id',
      profile.id,
      orderBy: 'display_order, id',
    ),
  );
}
