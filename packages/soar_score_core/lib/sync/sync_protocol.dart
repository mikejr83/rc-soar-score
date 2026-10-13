/// Version numbers of the sync protocol, specified in
/// `plan/architecture-requirements/sync-protocol.md`.
abstract final class SyncProtocol {
  /// The protocol version this build speaks.
  static const int protocolVersion = 1;

  /// The oldest protocol version this build still accepts.
  static const int minProtocolVersion = 1;

  /// The change count of one page of a pulled stream, unless the service
  /// lowers it.
  static const int defaultPageSize = 500;
}
