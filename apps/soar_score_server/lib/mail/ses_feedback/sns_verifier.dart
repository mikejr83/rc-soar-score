import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto_keys/crypto_keys.dart' show RsaPublicKey;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:x509/x509.dart' as x509;

import 'sns_message.dart';

final _logger = Logger('SnsVerifier');

/// The SNS topic the endpoint listens to, split from its ARN.
class SnsTopic {
  SnsTopic._(this.arn, this.region);

  final String arn;

  /// The region the topic lives in; SNS signs with a certificate served from
  /// `sns.{region}.amazonaws.com`.
  final String region;

  static final _arn = RegExp(
    r'^arn:aws:sns:([a-z]{2}-[a-z]+-\d):(\d{12}):[A-Za-z0-9_-]{1,256}$',
  );

  /// Parses a standard-partition SNS topic ARN, or returns null.
  static SnsTopic? parse(String arn) {
    final match = _arn.firstMatch(arn);
    return match == null ? null : SnsTopic._(arn, match.group(1)!);
  }

  /// The one host that may serve this topic's signing certificate and its
  /// subscription confirmation.
  String get host => 'sns.$region.amazonaws.com';

  /// Whether [url] is an https URL on [host] with no credentials and no
  /// unusual port.
  bool allowsUrl(String url, {String? pathSuffix}) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host != host) return false;
    if (uri.userInfo.isNotEmpty || (uri.hasPort && uri.port != 443)) {
      return false;
    }
    return pathSuffix == null || uri.path.endsWith(pathSuffix);
  }
}

/// Decides whether an SNS message is genuinely from the configured topic.
///
/// SNS cannot send a secret with a delivery, so the proof is the message's
/// RSA signature, checked against the certificate SNS names in
/// `SigningCertURL` (fetched only from the topic's own regional SNS host),
/// plus the topic ARN, which must be the configured one: anyone can create a
/// validly signed topic in their own AWS account.
class SnsVerifier {
  SnsVerifier({
    required this.topic,
    required this.client,
    this.timeout = const Duration(seconds: 5),
    this.maxCertificateBytes = 16 * 1024,
  });

  final SnsTopic topic;
  final http.Client client;
  final Duration timeout;
  final int maxCertificateBytes;

  // Certificates are few (SNS rotates rarely); keep the last ones by URL.
  final _certificates = <String, RsaPublicKey>{};
  static const _maxCachedCertificates = 4;

  /// Whether [message] is signed by SNS for the configured topic.
  ///
  /// False for a wrong topic, a certificate address that is not the topic
  /// region's SNS host, an unreadable or unreachable certificate, an unknown
  /// signature version, or a signature that does not match.
  Future<bool> verify(SnsMessage message) async {
    if (message.topicArn != topic.arn) return false;
    if (!topic.allowsUrl(message.signingCertUrl, pathSuffix: '.pem')) {
      return false;
    }
    final digest = switch (message.signatureVersion) {
      '1' => (pc.SHA1Digest(), '06052b0e03021a'),
      '2' => (pc.SHA256Digest(), '0609608648016503040201'),
      _ => null,
    };
    if (digest == null) return false;

    final Uint8List signature;
    try {
      signature = base64.decode(message.signature);
    } on FormatException {
      return false;
    }

    final key = await _certificateKey(message.signingCertUrl);
    if (key == null) return false;
    try {
      final verifier = pc.RSASigner(digest.$1, digest.$2)
        ..init(
          false,
          pc.PublicKeyParameter<pc.RSAPublicKey>(
            pc.RSAPublicKey(key.modulus, key.exponent),
          ),
        );
      return verifier.verifySignature(
        Uint8List.fromList(utf8.encode(message.stringToSign)),
        pc.RSASignature(signature),
      );
    } on Object {
      // pointycastle throws on a signature of the wrong length or shape.
      return false;
    }
  }

  Future<RsaPublicKey?> _certificateKey(String url) async {
    final cached = _certificates[url];
    if (cached != null) return cached;
    try {
      final response = await client.get(Uri.parse(url)).timeout(timeout);
      if (response.statusCode != 200 ||
          response.bodyBytes.length > maxCertificateBytes) {
        _logger.warning('The SNS signing certificate could not be fetched.');
        return null;
      }
      final parsed = x509.parsePem(utf8.decode(response.bodyBytes));
      final certificate = parsed.whereType<x509.X509Certificate>().firstOrNull;
      final key = certificate?.publicKey;
      if (key is! RsaPublicKey) return null;
      if (_certificates.length >= _maxCachedCertificates) {
        _certificates.remove(_certificates.keys.first);
      }
      return _certificates[url] = key;
    } on Object {
      _logger.warning('The SNS signing certificate could not be read.');
      return null;
    }
  }
}
