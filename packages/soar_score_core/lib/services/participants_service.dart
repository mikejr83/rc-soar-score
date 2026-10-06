import '../errors/contest_state_error.dart';
import '../errors/entity_not_found_error.dart';
import '../models/id.dart';
import '../models/participants/participant_profile.dart';
import '../models/participants/role.dart';
import '../repositories/already_stored_error.dart';
import '../repositories/mutation_metadata.dart';
import '../repositories/repository.dart';
import '../repositories/stale_revision_error.dart';
import 'participant_details.dart';

/// The participant profile operations of the API.
///
/// A profile belongs to the director that created it. Every operation takes
/// that director's account id and treats a profile of anyone else as not
/// found, so one director never learns that another's profile exists.
class ParticipantsService {
  ParticipantsService(this.repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Repository repository;
  final DateTime Function() _clock;

  /// The profiles owned by [ownerAccountId], in the order they were created.
  Future<List<ParticipantProfile>> list(Id ownerAccountId) =>
      repository.participantProfileRepository.listForOwner(ownerAccountId);

  /// The profile [id] of [ownerAccountId].
  ///
  /// Throws an [EntityNotFoundError] when there is none, or it is another
  /// director's.
  Future<ParticipantProfile> get(Id ownerAccountId, Id id) =>
      _require(ownerAccountId, id);

  /// Creates a profile owned by [ownerAccountId].
  ///
  /// Idempotent on [id]: repeating the same request returns the stored
  /// profile. The same id with different content throws an
  /// [AlreadyStoredError]. Invalid details throw an [ArgumentError].
  Future<ParticipantProfile> create(
    Id ownerAccountId,
    Id id,
    ParticipantDetails details, {
    required MutationMetadata metadata,
  }) async {
    final now = _clock();
    final profile = _build(
      id: id,
      ownerAccountId: ownerAccountId,
      details: details,
      createdAt: now,
      updatedAt: now,
    );
    final stored = await repository.participantProfileRepository.findById(id);
    if (stored != null) {
      if (stored.ownerAccountId == ownerAccountId &&
          _sameDetails(stored, profile)) {
        return stored;
      }
      throw AlreadyStoredError(entityType: 'ParticipantProfile', entityId: id);
    }
    return repository.participantProfileRepository.save(
      profile,
      metadata: metadata,
    );
  }

  /// Replaces the details of profile [id].
  ///
  /// Throws a [StaleRevisionError] when [baseRevision] is not the stored
  /// revision.
  Future<ParticipantProfile> update(
    Id ownerAccountId,
    Id id,
    ParticipantDetails details, {
    required int baseRevision,
    required MutationMetadata metadata,
  }) async {
    final stored = await _require(ownerAccountId, id);
    final updated = _build(
      id: id,
      ownerAccountId: ownerAccountId,
      details: details,
      createdAt: stored.createdAt,
      updatedAt: _clock(),
      revision: baseRevision,
    );
    return repository.participantProfileRepository.save(
      updated,
      metadata: metadata,
    );
  }

  /// Deletes profile [id]; returns nothing when it was removed.
  ///
  /// A profile that still has participations is refused with a
  /// [ContestStateError]: it is part of a contest's history.
  Future<void> delete(
    Id ownerAccountId,
    Id id, {
    required MutationMetadata metadata,
  }) async {
    await _require(ownerAccountId, id);
    final participations = await repository.contestParticipationRepository
        .listForProfile(id);
    if (participations.isNotEmpty) {
      throw ContestStateError(
        'has_participations',
        'the participant is in ${participations.length} contest(s); '
            'remove them from those first',
      );
    }
    await repository.participantProfileRepository.delete(
      id,
      metadata: metadata,
    );
  }

  /// The system roles and the roles [ownerAccountId] added, with their type.
  Future<List<Role>> roles(Id ownerAccountId) =>
      repository.roleRepository.listVisibleTo(ownerAccountId: ownerAccountId);

  Future<ParticipantProfile> _require(Id ownerAccountId, Id id) async {
    final profile = await repository.participantProfileRepository.findById(id);
    if (profile == null || profile.ownerAccountId != ownerAccountId) {
      throw EntityNotFoundError(entityType: 'ParticipantProfile', entityId: id);
    }
    return profile;
  }

  static ParticipantProfile _build({
    required Id id,
    required Id ownerAccountId,
    required ParticipantDetails details,
    required DateTime createdAt,
    required DateTime updatedAt,
    int revision = 0,
  }) => ParticipantProfile(
    id: id,
    ownerAccountId: ownerAccountId,
    firstName: details.firstName,
    lastName: details.lastName,
    club: _blankToNull(details.club),
    faiNumber: _blankToNull(details.faiNumber),
    nationalOrgId: _blankToNull(details.nationalOrgId),
    city: _blankToNull(details.city),
    state: _blankToNull(details.state),
    country: _blankToNull(details.country),
    email: _blankToNull(details.email)?.toLowerCase(),
    createdAt: createdAt,
    updatedAt: updatedAt,
    revision: revision,
  );

  static bool _sameDetails(ParticipantProfile a, ParticipantProfile b) =>
      a.firstName == b.firstName &&
      a.lastName == b.lastName &&
      a.club == b.club &&
      a.faiNumber == b.faiNumber &&
      a.nationalOrgId == b.nationalOrgId &&
      a.city == b.city &&
      a.state == b.state &&
      a.country == b.country &&
      a.email == b.email;

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
