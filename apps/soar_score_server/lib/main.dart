import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:soar_score_data_postgres/soar_score_data_postgres.dart';

import 'handler.dart';

int _portFromEnv() {
  const envKey = 'PORT';
  final value = Platform.environment[envKey];
  if (value == null || value.isEmpty) {
    return 8080;
  }
  final port = int.tryParse(value);
  if (port == null || port < 1 || port > 65535) {
    stderr.writeln('Invalid $envKey value "$value"; using 8080.');
    return 8080;
  }
  return port;
}

Future<void> main() async {
  final port = _portFromEnv();
  final config = PostgresConfig.fromEnvironment();
  if (config == null) {
    stderr.writeln(
      'POSTGRES_PASSWORD is not set; the API cannot open its database. '
      'Configure the PostgreSQL connection environment variables (see '
      'soar_score_data_postgres) and retry.',
    );
    exit(1);
  }
  final server = await shelf_io.serve(
    createServerHandler(config),
    InternetAddress.anyIPv4,
    port,
  );
  stdout.writeln('$serverName listening on http://localhost:${server.port}');
}
