/// The most bytes a `POST /sync/exchange` body may hold. A client splits its
/// pending mutations into exchanges that fit, so the service and the client
/// share these numbers.
const int syncExchangeMaxBodyBytes = 16 * 1024 * 1024;

/// The most mutations one `POST /sync/exchange` may carry.
const int syncExchangeMaxMutations = 10000;
