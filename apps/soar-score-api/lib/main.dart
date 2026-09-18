import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_data/soar_score_data.dart';

final Logger _logger = Logger('score-soar-api');

Future<void> main() async {
  // The logging package installs a default console handler that prints
  // records at or below the root level. shelf's logRequests() middleware
  // emits request records through the same logger hierarchy.
  Logger.root.level = Level.INFO;

  // Wire the domain-aware API server. The in-memory repository is the
  // default backing store; a persistent store can be swapped in here
  // without touching the server or this entrypoint.
  final repository = InMemoryContestRepository();
  final server = ContestServer(repository: repository);

  final pipeline = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(server.handler);

  final hosted = await serve(pipeline.call, '0.0.0.0', 8080);
  _logger
      .info('API server running at http://${hosted.address.address}:${hosted.port}');
}