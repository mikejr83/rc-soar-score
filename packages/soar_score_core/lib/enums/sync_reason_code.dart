/// Why the service rejected, conflicted or skipped a mutation, or refused a
/// sync request.
///
/// The single list shared by server and client, specified in
/// `plan/architecture-requirements/sync-protocol.md`. [code] is the exact
/// text on the wire and in `MutationRecord.reasonCode`.
enum SyncReasonCode {
  staleBase('stale_base'),
  configRevisionConflict('config_revision_conflict'),
  inactiveInstallation('inactive_installation'),
  unknownMatrixRevision('unknown_matrix_revision'),
  unknownFlightGroup('unknown_flight_group'),
  entityDeleted('entity_deleted'),
  uniqueViolation('unique_violation'),
  locked('locked'),
  unauthorized('unauthorized'),
  directorOverParticipant('director_over_participant'),
  scoredAssignment('scored_assignment'),
  dependencyFailed('dependency_failed'),
  unsupportedProtocolVersion('unsupported_protocol_version'),
  schemaTooOld('schema_too_old'),
  reclaimRequiresSync('reclaim_requires_sync'),
  contestExists('contest_exists'),
  invalidPayload('invalid_payload');

  const SyncReasonCode(this.code);

  /// The text sent on the wire and stored with a mutation.
  final String code;

  /// The reason for [code], or null when it is not in the list (for example a
  /// code from a newer service).
  static SyncReasonCode? tryParse(String? code) {
    for (final reason in values) {
      if (reason.code == code) return reason;
    }
    return null;
  }
}
