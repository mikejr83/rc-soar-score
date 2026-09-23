import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;

import 'handler.dart';
import 'health_handler.dart';

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
  final server = await shelf_io.serve(
    createServerHandler(),
    InternetAddress.anyIPv4,
    port,
  );
  stdout.writeln('$serverName listening on http://localhost:${server.port}');
}
