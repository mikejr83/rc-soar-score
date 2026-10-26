import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

/// The databases the shared suite runs against.
enum Backend { sqlite, postgres }

/// The PostgreSQL server to test against, from the environment; null when
/// neither `DATABASE_URL` nor `POSTGRES_PASSWORD` is set.
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
          ? 'no PostgreSQL instance configured (set DATABASE_URL or POSTGRES_PASSWORD; see the README for a local server)'
          : false,
    );
  }
}

/// Runs [body] on PostgreSQL only, for backend-only entities that an
/// installation never has. Reported as skipped when no server is configured.
void forPostgresOnly(void Function(Backend backend) body) {
  group(
    Backend.postgres.name,
    () => body(Backend.postgres),
    skip: postgresConfig == null
        ? 'no PostgreSQL instance configured (set DATABASE_URL or POSTGRES_PASSWORD; see the README for a local server)'
        : false,
  );
}
