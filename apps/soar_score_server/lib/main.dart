import 'dart:async';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';

import 'config/config_exception.dart';
import 'config/server_config.dart';
import 'logging/log_setup.dart';
import 'server.dart';

final _logger = Logger('Main');

/// Starts the API server: reads the environment, opens the database and
/// serves until SIGINT or SIGTERM.
Future<void> main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load();

  final ServerConfig config;
  try {
    config = ServerConfig.parse({
      for (final key in ServerConfig.environmentKeys)
        if (env[key] != null) key: env[key]!,
    });
  } on ConfigException catch (e) {
    stderr.writeln(e);
    exit(1);
  }

  configureLogging(level: config.logLevel, format: config.logFormat);
  _logger.info('Starting with ${config.describe()}');

  final RunningServer server;
  try {
    server = await startServer(config, onDatabaseOpen: seedSystemData);
  } catch (e, stack) {
    _logger.severe('Could not start the server.', e, stack);
    exit(1);
  }

  final stopped = Completer<void>();
  void stop(ProcessSignal signal) {
    _logger.info('Received ${signal.name}.');
    server.close().whenComplete(() {
      if (!stopped.isCompleted) stopped.complete();
    });
  }

  ProcessSignal.sigint.watch().listen(stop);
  // SIGTERM is not available on Windows.
  if (!Platform.isWindows) ProcessSignal.sigterm.watch().listen(stop);

  await stopped.future;
  exit(0);
}
