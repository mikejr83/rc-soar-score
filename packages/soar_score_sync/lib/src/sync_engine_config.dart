import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Settings for one [SyncEngine].
class SyncEngineConfig {
  const SyncEngineConfig({
    required this.installationId,
    required this.label,
    required this.platform,
    required this.schemaVersion,
    this.protocolVersion = SyncProtocol.protocolVersion,
    this.isSyncable,
    this.now = _systemNow,
    this.capabilityRecheckInterval = const Duration(minutes: 1),
    this.maxExchangeBytes = syncExchangeMaxBodyBytes,
    this.maxExchangeMutations = syncExchangeMaxMutations,
    this.slowExchange = const Duration(seconds: 10),
  });

  /// This installation's own identifier, generated once and kept.
  final Id installationId;

  /// The name the director recognizes, for example "Field laptop".
  final String label;

  final Platform platform;

  /// The local data schema version, sent with every exchange.
  final int schemaVersion;

  final int protocolVersion;

  /// Whether the engine may sync [scope]. Null means every scope. Return
  /// false for an accountless contest.
  final Future<bool> Function(SyncScopeKey scope)? isSyncable;

  /// The service's limits on one exchange; a push is cut to fit them.
  final int maxExchangeBytes;
  final int maxExchangeMutations;

  /// An exchange that takes at least this long is logged as a warning.
  final Duration slowExchange;

  /// How long a scope with `promote_score` intents held back waits before it
  /// reads the service's capabilities again.
  final Duration capabilityRecheckInterval;

  /// The clock, replaceable in tests.
  final DateTime Function() now;

  static DateTime _systemNow() => DateTime.now().toUtc();
}
