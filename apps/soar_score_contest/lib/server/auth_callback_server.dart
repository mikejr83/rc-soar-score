import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import '../auth/auth_callback_listener.dart';
import '../auth/auth_session.dart';
import 'auth_callback_pages.dart';

final _logger = Logger('AuthCallbackServer');

/// Longest query value taken over from Auth0's redirect.
const int _maxValueLength = 2048;

/// The loopback web listener for Windows sign-in and sign-out.
///
/// Auth0 redirects the browser to `http://localhost:<port>/callback` (or
/// `/logout`). The listener answers with a page that says the window can be
/// closed and passes the callback on to [appScheme]`://callback`, which
/// Windows hands to the running app. It only ever forwards to that scheme, so
/// it cannot be used as an open redirect, and it serves nothing but these two
/// pages. It runs only between [start] and [stop], not for the whole life of
/// the app, and it is separate from the embedded API server because the API
/// acts as the Local account without a token and so must stay on a random
/// port.
class AuthCallbackServer implements AuthCallbackListener {
  AuthCallbackServer({required this.port, required this.appScheme});

  final int port;

  /// The custom URL scheme the callback is handed to.
  final String appScheme;

  HttpServer? _server;

  @override
  Future<void> start() async {
    if (_server != null) {
      return;
    }
    try {
      final server = await HttpServer.bind('localhost', port);
      _server = server;
      unawaited(server.forEach(_handle));
    } on SocketException catch (error) {
      _logger.warning('Could not listen on port $port', error);
      throw AuthException(
        'Sign-in needs port $port on this computer, and another program is '
        'using it. Close that program and try again.',
      );
    }
  }

  @override
  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    try {
      final (status, body) = _answer(request);
      response
        ..statusCode = status
        ..headers.contentType = ContentType.html
        // The query holds the authorization code: keep it out of caches and
        // referrers.
        ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
        ..headers.set('Referrer-Policy', 'no-referrer')
        ..headers.set('X-Content-Type-Options', 'nosniff')
        ..headers.set(
          'Content-Security-Policy',
          "default-src 'none'; style-src 'unsafe-inline'; "
              "script-src 'unsafe-inline'",
        )
        ..write(body);
    } on Object catch (error, stackTrace) {
      _logger.warning('Callback request failed', error, stackTrace);
      response.statusCode = HttpStatus.internalServerError;
    } finally {
      await response.close();
    }
  }

  (int, String) _answer(HttpRequest request) {
    if (request.method != 'GET') {
      return (HttpStatus.methodNotAllowed, authCallbackRejectedPage());
    }
    switch (request.uri.path) {
      case '/callback':
        return _callback(request.uri.queryParameters);
      case '/logout':
        return (
          HttpStatus.ok,
          authCallbackDonePage(
            heading: 'You are signed out',
            appUrl: _appUrl(const {}),
          ),
        );
      default:
        return (HttpStatus.notFound, authCallbackRejectedPage());
    }
  }

  (int, String) _callback(Map<String, String> query) {
    final error = query['error'];
    if (error != null && error.isNotEmpty) {
      final description = query['error_description'];
      return (
        HttpStatus.ok,
        authCallbackErrorPage(
          detail: _clip(
            description == null || description.isEmpty ? error : description,
          ),
          appUrl: _appUrl({
            'error': _clip(error),
            'error_description': ?(description == null
                ? null
                : _clip(description)),
          }),
        ),
      );
    }
    final code = query['code'];
    final state = query['state'];
    if (code == null || code.isEmpty || state == null || state.isEmpty) {
      return (HttpStatus.badRequest, authCallbackRejectedPage());
    }
    return (
      HttpStatus.ok,
      authCallbackDonePage(
        heading: 'You are signed in',
        appUrl: _appUrl({'code': _clip(code), 'state': _clip(state)}),
      ),
    );
  }

  Uri _appUrl(Map<String, String> query) => Uri(
    scheme: appScheme,
    host: 'callback',
    queryParameters: query.isEmpty ? null : query,
  );

  static String _clip(String value) => value.length > _maxValueLength
      ? value.substring(0, _maxValueLength)
      : value;
}
