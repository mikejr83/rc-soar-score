/// The liveness of a single connectivity indicator.
///
/// [ConnectivityStatus.unknown] is the initial state and is also used when no
/// remote API is configured: the indicator has not yet been observed, or there
/// is nothing to observe.
enum ConnectivityStatus { unknown, checking, available, unavailable }