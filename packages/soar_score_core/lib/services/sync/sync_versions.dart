import '../../errors/sync_refusal.dart';
import '../../sync/sync_protocol.dart';

/// The protocol and schema ranges the service accepts, and the check that
/// runs before anything else in a sync request.
class SyncVersions {
  const SyncVersions({
    required this.minSchemaVersion,
    required this.maxSchemaVersion,
  });

  /// A service whose database is at one [schemaVersion] accepts that version
  /// only, since an installation on a different schema stores different
  /// payloads.
  const SyncVersions.exactly(int schemaVersion)
    : minSchemaVersion = schemaVersion,
      maxSchemaVersion = schemaVersion;

  final int minSchemaVersion;
  final int maxSchemaVersion;

  int get protocolVersion => SyncProtocol.protocolVersion;
  int get minProtocolVersion => SyncProtocol.minProtocolVersion;

  /// Refuses a client outside the supported range, before any mutation is
  /// looked at.
  ///
  /// A protocol outside the range and a schema below the minimum answer
  /// `426` (update the app); a schema above the maximum answers `409`
  /// (the service is older than the app; update later).
  void require({required int protocolVersion, required int schemaVersion}) {
    if (protocolVersion < minProtocolVersion ||
        protocolVersion > this.protocolVersion) {
      throw SyncRefusal(
        'unsupported_protocol_version',
        426,
        'Protocol version $protocolVersion is not supported; this service '
            'speaks $minProtocolVersion to ${this.protocolVersion}. Update '
            'the app.',
      );
    }
    if (schemaVersion < minSchemaVersion) {
      throw SyncRefusal(
        'schema_too_old',
        426,
        'Schema version $schemaVersion is too old; the minimum is '
            '$minSchemaVersion. Update the app.',
      );
    }
    if (schemaVersion > maxSchemaVersion) {
      throw SyncRefusal(
        'unsupported_protocol_version',
        409,
        'Schema version $schemaVersion is newer than this service supports '
            '($maxSchemaVersion). Try again after the service is updated.',
      );
    }
  }
}
