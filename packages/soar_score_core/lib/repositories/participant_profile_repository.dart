import '../models/id.dart';
import '../models/participants/participant_profile.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [ParticipantProfile]s.
abstract interface class ParticipantProfileRepository {
  Future<ParticipantProfile?> findById(Id id);

  /// The profiles owned by [accountId], in the order they were created.
  Future<List<ParticipantProfile>> listForOwner(Id accountId);

  /// Inserts [profile], or updates the stored row with the same id.
  ///
  /// Throws a `StaleRevisionError` when [profile] was read at an older
  /// revision. Returns the profile as stored.
  Future<ParticipantProfile> save(
    ParticipantProfile profile, {
    required MutationMetadata metadata,
  });

  /// Saves all of [profiles] in one transaction, as [save] does for each: a
  /// failure on any of them stores none. Each profile is written with
  /// `metadata.forPart(profile.id.value)`. Returns the profiles as stored, in
  /// order.
  Future<List<ParticipantProfile>> saveAll(
    List<ParticipantProfile> profiles, {
    required MutationMetadata metadata,
  });

  /// Deletes the profile with [id]; returns whether a row was removed.
  ///
  /// A profile that still has participations cannot be deleted.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
