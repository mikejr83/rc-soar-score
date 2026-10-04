/// Marker for entities that hold private personal or credential data.
///
/// Publication models must never hold a [PrivateData] value; a test keeps a
/// hand-written list of their fields so adding one fails the build.
abstract interface class PrivateData {}
