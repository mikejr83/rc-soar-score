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

  /// Installs [profile] unless its row exists. Writes the profile and its
  /// child rows in one transaction, unless the caller is already in one
  /// ([atomic] false).
  @override
  Future<bool> installSystemProfile(
    core.DisciplineProfileWithRules profile, {
    bool atomic = true,
  }) {
    Future<bool> install() async {
      final head = profile.profile;
      if (await _profiles.findJson(head.id) != null) return false;
      final tableId = head.defaultLandingTableId;
      if (tableId != null && await _landingTables.findJson(tableId) == null) {
        throw StateError(
          'The default landing table ${tableId.value} of ${head.name} is '
          'not installed; install the landing tables first.',
        );
      }
      await _profiles.insertMissingJson([_profiles.encode(head)]);
      await _configFields.insertMissingJson([
        for (final row in profile.configFields) _configFields.encode(row),
      ]);
      await _scoreFields.insertMissingJson([
        for (final row in profile.scoreFields) _scoreFields.encode(row),
      ]);
      await _validations.insertMissingJson([
        for (final row in profile.validations) _validations.encode(row),
      ]);
      await _formulas.insertMissingJson([
        for (final row in profile.formulas) _formulas.encode(row),
      ]);
      await _rules.insertMissingJson([
        for (final row in profile.rules) _rules.encode(row),
      ]);
      return true;
    }

    return atomic ? db.transaction(install) : install();
  }

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
