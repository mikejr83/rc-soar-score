import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

/// The databases the shared suite runs against.
enum Backend { sqlite, postgres }

/// The PostgreSQL server to test against, from the environment; null when
/// `POSTGRES_PASSWORD` is not set.
PostgresConfig? get postgresConfig => PostgresConfig.fromEnvironment();

/// Runs [body] once for every backend, each in its own group.
///
/// The PostgreSQL group is reported as skipped when no server is configured.
/// A skip is not a pass: the suite only counts as run on PostgreSQL when that
/// group ran.
void forEachBackend(void Function(Backend backend) body) {
  final postgresMissing = postgresConfig == null;
  for (final backend in Backend.values) {
    group(
      backend.name,
      () => body(backend),
      skip: backend == Backend.postgres && postgresMissing
          ? 'POSTGRES_PASSWORD is not set (see the README for a local server)'
          : false,
    );
  }
}
