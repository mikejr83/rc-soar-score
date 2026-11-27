import 'dart:convert';

/// The kinds of SNS message the feedback endpoint understands.
enum SnsMessageType {
  notification('Notification'),
  subscriptionConfirmation('SubscriptionConfirmation'),
  unsubscribeConfirmation('UnsubscribeConfirmation');

  const SnsMessageType(this.wire);
  final String wire;

  static SnsMessageType? fromWire(Object? value) {
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return null;
  }
}

/// One message SNS posted to an HTTPS endpoint, with the fields that its
/// signature covers.
///
/// Parsing checks only the shape. [SnsVerifier] decides whether the message
/// is genuine; nothing in a message is to be believed before that.
class SnsMessage {
  SnsMessage._({
    required this.type,
    required this.messageId,
    required this.topicArn,
    required this.message,
    required this.timestamp,
    required this.signatureVersion,
    required this.signature,
    required this.signingCertUrl,
    this.subject,
    this.subscribeUrl,
    this.token,
  });

  final SnsMessageType type;
  final String messageId;
  final String topicArn;

  /// The payload; for an SES notification, a JSON document as text.
  final String message;
  final String timestamp;
  final String? subject;

  /// `SubscriptionConfirmation` and `UnsubscribeConfirmation` only.
  final String? subscribeUrl;
  final String? token;

  /// `1` (SHA-1) or `2` (SHA-256).
  final String signatureVersion;

  /// Base64 of the RSA signature.
  final String signature;
  final String signingCertUrl;

  /// Reads [body], the text of a request, or returns null when it is not an
  /// SNS message of a known type with every field its signature needs.
  static SnsMessage? parse(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    final json = decoded;
    String? text(String key) {
      final value = json[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    final type = SnsMessageType.fromWire(json['Type']);
    final messageId = text('MessageId');
    final topicArn = text('TopicArn');
    // A message may be empty text, which the signature still covers.
    final message = json['Message'];
    final timestamp = text('Timestamp');
    final version = text('SignatureVersion');
    final signature = text('Signature');
    final certUrl = text('SigningCertURL');
    if (type == null ||
        messageId == null ||
        topicArn == null ||
        message is! String ||
        timestamp == null ||
        version == null ||
        signature == null ||
        certUrl == null) {
      return null;
    }
    final subscribeUrl = text('SubscribeURL');
    final token = text('Token');
    if (type != SnsMessageType.notification &&
        (subscribeUrl == null || token == null)) {
      return null;
    }
    return SnsMessage._(
      type: type,
      messageId: messageId,
      topicArn: topicArn,
      message: message,
      timestamp: timestamp,
      signatureVersion: version,
      signature: signature,
      signingCertUrl: certUrl,
      subject: text('Subject'),
      subscribeUrl: subscribeUrl,
      token: token,
    );
  }

  /// The text SNS signed: each covered field as `Name\nValue\n`, in the order
  /// the SNS documentation gives. A notification's `Subject` is covered only
  /// when it is present.
  String get stringToSign {
    final fields = type == SnsMessageType.notification
        ? [
            ('Message', message),
            ('MessageId', messageId),
            if (subject != null) ('Subject', subject!),
            ('Timestamp', timestamp),
            ('TopicArn', topicArn),
            ('Type', type.wire),
          ]
        : [
            ('Message', message),
            ('MessageId', messageId),
            ('SubscribeURL', subscribeUrl!),
            ('Timestamp', timestamp),
            ('Token', token!),
            ('TopicArn', topicArn),
            ('Type', type.wire),
          ];
    return [for (final (name, value) in fields) '$name\n$value\n'].join();
  }
}
