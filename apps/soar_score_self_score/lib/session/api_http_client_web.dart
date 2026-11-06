import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// The HTTP client for the API. It sends the guest session cookie, which the
/// API sets on its own origin, with every request.
http.Client openApiHttpClient() => BrowserClient()..withCredentials = true;
