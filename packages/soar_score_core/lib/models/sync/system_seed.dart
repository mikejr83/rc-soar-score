/// The version of the system data the app ships.
///
/// Raise [sequence] whenever any shipped system data changes (a landing
/// table, a discipline profile or a role). A native installation records the
/// sequence it has installed as its system-data position, so a later launch
/// skips the install and a launch after an upgrade installs again. The
/// server's system-data stream holds the shipped set at or below
/// [sequence], so the first synchronization starts after it.
abstract final class SystemSeed {
  static const int sequence = 1;
}
