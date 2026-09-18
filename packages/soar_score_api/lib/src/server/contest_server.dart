import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// HTTP server for contest API endpoints.
class ContestServer {
  final Router _router;

  ContestServer()
      : _router = Router() {
    _router.get('/contest', (request) {
      return Response.ok('{"status": "ok"}');
    });
  }

  /// Get the shelf handler.
  Handler get handler => _router;
}