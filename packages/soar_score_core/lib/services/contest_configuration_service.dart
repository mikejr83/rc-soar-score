import '../enums/audit_action.dart';
import '../enums/audit_outcome.dart';
import '../enums/config_field_type.dart';
import '../enums/profile_status.dart';
import '../errors/contest_state_error.dart';
import '../errors/entity_not_found_error.dart';
import '../models/contest/contest.dart';
import '../models/contest/contest_configuration_revision.dart';
import '../models/contest/core_options.dart';
import '../models/contest/saved_configuration.dart';
import '../models/discipline/discipline_profile_with_rules.dart';
import '../models/id.dart';
import '../models/sync/audit_event.dart';
import '../repositories/mutation_metadata.dart';
import '../repositories/repository.dart';
import '../repositories/stale_revision_error.dart';
import 'configuration_input.dart';
import 'contest_configuration_rules.dart';
import 'discipline_config_validator.dart';

/// Reads and saves the configuration of a contest.
///
/// A configuration is append-only: every save adds the next revision, with
/// the full settings and the discipline profile and landing table they are
/// for. Callers name who acts through [createdBy] and the [MutationMetadata].
/// Each save leaves one `ConfigurationSaved` audit event, stored with it.
class ContestConfigurationService {
  ContestConfigurationService(
    this.repository, {
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create;

  final Repository repository;
  final DateTime Function() _clock;
  final Id Function() _newId;

  /// The latest configuration revision of contest [contestId].
  ///
  /// Throws an [EntityNotFoundError] when the contest does not exist or has
  /// no configuration yet.
  Future<ContestConfigurationRevision> latest(Id contestId) async {
    await _requireContest(contestId);
    final revision = await repository.contestConfigurationRevisionRepository
        .latestForContest(contestId);
    if (revision == null) {
      throw EntityNotFoundError(
        entityType: 'ContestConfigurationRevision',
        entityId: contestId,
      );
    }
    return revision;
  }

  /// Every configuration revision of contest [contestId], oldest first.
  Future<List<ContestConfigurationRevision>> revisions(Id contestId) async {
    await _requireContest(contestId);
    return repository.contestConfigurationRevisionRepository.listForContest(
      contestId,
    );
  }

  /// Saves [input] as the next configuration revision of contest [contestId]
  /// and moves the contest's state as the lifecycle rules say.
  ///
  /// Throws:
  /// - `EntityNotFoundError` for an unknown contest;
  /// - `StaleRevisionError` when [ConfigurationInput.baseRevisionNumber] is
  ///   not the latest revision number, or the contest changed meanwhile;
  /// - `ArgumentError` or `ScoringValidationError` for an unknown or
  ///   unpublished profile, an unusable landing table, a bad core option or
  ///   a bad discipline setting (all reported together);
  /// - `ContestStateError` when the contest's state does not allow the
  ///   change (locked, completed, fixed while running, or a different
  ///   discipline).
  Future<SavedConfiguration> save(
    Id contestId,
    ConfigurationInput input, {
    required Id createdBy,
    required MutationMetadata metadata,
  }) async {
    final contest = await _requireContest(contestId);
    final revisions = repository.contestConfigurationRevisionRepository;
    final previous = await revisions.latestForContest(contestId);
    final latestNumber = previous?.revisionNumber ?? 0;
    if (input.baseRevisionNumber != latestNumber) {
      throw StaleRevisionError(
        entityType: 'ContestConfigurationRevision',
        entityId: contestId,
        expectedRevision: input.baseRevisionNumber,
        storedRevision: latestNumber,
      );
    }

    final profile = await _requireProfile(input.disciplineProfileId);
    if (previous != null &&
        previous.disciplineProfileId != input.disciplineProfileId) {
      throw ContestStateError(
        'discipline_fixed',
        'The discipline is chosen with the first configuration and cannot '
            'change.',
      );
    }

    _validateCore(input);
    DisciplineConfigValidator.validate(profile, input.config.discipline);
    final landingTableId = await _resolveLandingTable(
      profile,
      input.landingTableId,
      contest,
    );

    final now = _clock();
    final revision = ContestConfigurationRevision(
      id: _newId(),
      contestId: contestId,
      revisionNumber: latestNumber + 1,
      disciplineProfileId: input.disciplineProfileId,
      config: input.config,
      landingTableId: landingTableId,
      createdBy: createdBy,
      notes: _blankToNull(input.notes),
      createdAt: now,
    );
    final changed = ContestConfigurationRules.apply(
      contest,
      previous,
      revision,
      now,
    );
    final audit = AuditEvent(
      id: _newId(),
      entityType: revision.entityType,
      entityId: revision.id,
      contestId: contestId,
      action: AuditAction.configurationSaved,
      actorId: metadata.actorId,
      authority: metadata.authority,
      installationId: metadata.sourceInstallationId,
      device: metadata.sourceDevice,
      baseRevision: previous?.revisionNumber,
      resultingRevision: revision.revisionNumber,
      serverTimestamp: now,
      clientTimestamp: metadata.clientTime,
      outcome: AuditOutcome.success,
    );
    return revisions.appendWithContest(
      revision,
      contest: changed,
      metadata: metadata,
      audit: audit,
    );
  }

  Future<Contest> _requireContest(Id id) async {
    final contest = await repository.contestRepository.findById(id);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: id);
    }
    return contest;
  }

  Future<DisciplineProfileWithRules> _requireProfile(Id id) async {
    final profile = await repository.disciplineProfileRepository.findById(id);
    if (profile == null) {
      throw ArgumentError.value(
        id.value,
        'discipline_profile_id',
        'is not a known discipline profile',
      );
    }
    if (profile.profile.status != ProfileStatus.published) {
      throw ArgumentError.value(
        id.value,
        'discipline_profile_id',
        'is not a published discipline profile',
      );
    }
    return profile;
  }

  /// Rejects an unknown `core` key and any invalid core option.
  static void _validateCore(ConfigurationInput input) {
    final unknown = input.config.core.keys.where(
      (key) => !CoreOptions.knownKeys.contains(key),
    );
    if (unknown.isNotEmpty) {
      throw ArgumentError.value(
        unknown.join(', '),
        'config.core',
        'holds settings that do not exist',
      );
    }
    input.config.coreOptions;
  }

  /// The landing table a revision uses: the one asked for, else the
  /// profile's default, and none for a discipline that does not score
  /// landings. A table must exist and be a system table or the contest
  /// owner's.
  Future<Id?> _resolveLandingTable(
    DisciplineProfileWithRules profile,
    Id? requested,
    Contest contest,
  ) async {
    final scoresLandings = profile.configFields.any(
      (f) => f.fieldType == ConfigFieldType.landing,
    );
    if (!scoresLandings) {
      if (requested != null) {
        throw ArgumentError.value(
          requested.value,
          'landing_table_id',
          'is not used by ${profile.profile.name}',
        );
      }
      return null;
    }
    final id = requested ?? profile.profile.defaultLandingTableId;
    if (id == null) return null;

    final table = await repository.landingTableRepository.findById(id);
    final usable =
        table != null &&
        (table.table.isSystem ||
            table.table.ownerAccountId == contest.ownerAccountId);
    if (!usable) {
      throw ArgumentError.value(
        id.value,
        'landing_table_id',
        'is not a landing table this contest can use',
      );
    }
    return id;
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
