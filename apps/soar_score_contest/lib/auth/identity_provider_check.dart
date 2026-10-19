// ignore_for_file: prefer_initializing_formals
// The public constructor parameter names are part of this check's
// documented API, so the initializer list stands in for initializing
// formal fields.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// The reachability of the app's identity provider (Auth0).
enum IdentityProviderStatus { checking, available, unavailable }

/// Probes the identity provider's OpenID discovery document and reports
/// its reachability to listeners.
///
/// A probe is a lightweight `GET /.well-known/openid-configuration` against
/// the tenant's domain with [timeout]. Any 2xx response makes the provider
/// [IdentityProviderStatus.available]; a network failure, a timeout, or a
/// non-2xx response makes it [IdentityProviderStatus.unavailable] and records
/// a short user-facing reason in [lastError].
class IdentityProviderCheck extends ChangeNotifier {
  /// Probes the identity provider at [tenantDomain]. [client] is injectable
  /// for tests; [timeout] bounds a single probe. A client the check creates
  /// itself is closed when the check is disposed; an injected client stays
  /// open, its owner remaining responsible for closing it.
  IdentityProviderCheck({
    required String tenantDomain,
    http.Client? client,
    Duration timeout = const Duration(seconds: 5),
  }) : _probeUrl = Uri.https(tenantDomain, '/.well-known/openid-configuration'),
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _timeout = timeout;

  final Uri _probeUrl;
  final http.Client _client;
  final bool _ownsClient;
  final Duration _timeout;

  IdentityProviderStatus _status = IdentityProviderStatus.checking;
  String? _lastError;
  bool _probeInFlight = false;
  bool _disposed = false;

  /// Current reachability. [IdentityProviderStatus.checking] both before the
  /// first probe completes and while a later one is in flight.
  IdentityProviderStatus get status => _status;

  /// Short user-facing reason for the latest failure (for example
  /// 'Timed out', 'HTTP 500' or 'No network connection'); null while
  /// available or before any probe has failed and been resolved.
  String? get lastError => _lastError;

  /// Probes the identity provider once. Single-flight: a probe requested
  /// while one is in flight is skipped (never chained), so fast retries
  /// cannot pile up requests.
  Future<void> probe() {
    if (_disposed || _probeInFlight) {
      return Future.value();
    }
    _probeInFlight = true;
    _set(IdentityProviderStatus.checking);
    return _runProbe();
  }

  /// Convenience start without awaiting the result.
  void check() {
    probe();
  }

  Future<void> _runProbe() async {
    http.Response? response;
    try {
      response = await _client.get(_probeUrl).timeout(_timeout);
    } on TimeoutException {
      _fail('Timed out');
    } on Object {
      _fail('No network connection');
    } finally {
      _probeInFlight = false;
    }
    if (_disposed) {
      return;
    }
    if (response == null) {
      return;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _lastError = null;
      _set(IdentityProviderStatus.available);
    } else {
      _fail('HTTP ${response.statusCode}');
    }
  }

  void _fail(String reason) {
    _lastError = reason;
    _set(IdentityProviderStatus.unavailable);
  }

  void _set(IdentityProviderStatus value) {
    if (_disposed || value == _status) {
      return;
    }
    _status = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _probeInFlight = false;
    if (_ownsClient) {
      _client.close();
    }
    super.dispose();
  }
}
