import 'package:soar_score_core/soar_score_core.dart';

/// The scope as written in a log line. A director scope is named by kind
/// only, so the account is not written to the log.
String syncScopeLabel(SyncScopeKey scope) => switch (scope) {
  ContestScopeKey(:final contestId) => 'contest/${contestId.value}',
  DirectorScopeKey() => 'director',
  SystemScopeKey() => 'system',
};
