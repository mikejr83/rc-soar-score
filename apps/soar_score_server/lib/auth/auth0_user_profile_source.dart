import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';

/// Reads a person's name and email from Auth0's `/userinfo` endpoint.
///
/// Called once, when a new identity first signs in. A token requested with
/// the `openid profile email` scopes is accepted there.
class Auth0UserProfileSource implements UserProfileSource {
  Auth0UserProfileSource({
    required String domain,
    http.Client? client,
    this.timeout = const Duration(seconds: 5),
  }) : _url = Uri.https(domain, '/userinfo'),
       _client = client ?? http.Client();

  final Uri _url;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<UserProfile> fetch(String accessToken) async {
    final http.Response response;
    try {
      response = await _client
          .get(_url, headers: {'authorization': 'Bearer $accessToken'})
          .timeout(timeout);
    } on Object catch (e) {
      throw UserProfileUnavailableException('request failed: $e');
    }
    if (response.statusCode != 200) {
      throw UserProfileUnavailableException('status ${response.statusCode}');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const UserProfileUnavailableException('not JSON');
    }
    if (decoded is! Map<String, Object?>) {
      throw const UserProfileUnavailableException('not an object');
    }
    final body = decoded;
    String? text(String key) {
      final value = body[key];
      return value is String ? value : null;
    }

    return UserProfile(
      givenName: text('given_name'),
      familyName: text('family_name'),
      name: text('name'),
      email: text('email'),
      emailVerified: body['email_verified'] == true,
    );
  }

  void close() => _client.close();
}
