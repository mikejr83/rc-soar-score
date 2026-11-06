import 'package:http/http.dart' as http;

/// The HTTP client for the API. Off the web there are no cookies to send.
http.Client openApiHttpClient() => http.Client();
