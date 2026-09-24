import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:soar_score_data_postgres/soar_score_data_postgres.dart';

import 'handler.dart';

final _logger = Logger('Main');

int _portFromEnv(DotEnv env) {
  const envKey = 'PORT';
  final value = env[envKey];
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
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    if (record.error != null) print(record.error);
    if (record.stackTrace != null) print(record.stackTrace);
  });

  final env = DotEnv(includePlatformEnvironment: true)..load();

  final port = _portFromEnv(env);
  var config = PostgresConfig.fromEnvironment();

  if (config == null && env['POSTGRES_PASSWORD'] != null) {
    final password = env['POSTGRES_PASSWORD'];
    // You can use the password here to create a new PostgresConfig if needed

    if (password?.isEmpty ?? true) {
      _logger.warning('POSTGRES_PASSWORD is empty; using it to create PostgresConfig anyway.');
    } else {
      _logger.info('Using POSTGRES_PASSWORD from environment to create PostgresConfig.');
    }

    config = PostgresConfig(
      database: 'soar_score',
      host: "localhost",
      port: 5432,
      user: 'postgres',
      password: password!,
    );
  }

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
