import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_server/mail/ses_feedback/sns_message.dart';
import 'package:soar_score_server/mail/ses_feedback/sns_verifier.dart';
import 'package:test/test.dart';

import 'sns_test_signing.dart';

void main() {
  late List<Uri> fetched;
  late http.Client client;
  late SnsVerifier verifier;
  var certificateStatus = 200;

  setUp(() {
    fetched = [];
    certificateStatus = 200;
    client = MockClient((request) async {
      fetched.add(request.url);
      return http.Response(
        certificateStatus == 200 ? testSigningCertPem : 'no',
        certificateStatus,
      );
    });
    verifier = SnsVerifier(
      topic: SnsTopic.parse(testTopicArn)!,
      client: client,
    );
  });

  SnsMessage parse(Map<String, Object?> fields) =>
      SnsMessage.parse(jsonEncode(fields))!;

  group('SnsTopic', () {
    test('parses a standard SNS topic ARN and names its host', () {
      final topic = SnsTopic.parse(testTopicArn)!;
      expect(topic.region, 'us-east-2');
      expect(topic.host, 'sns.us-east-2.amazonaws.com');
    });

    test('refuses anything else', () {
      for (final bad in [
        '',
        'arn:aws:sqs:us-east-2:123456789012:q',
        'arn:aws-cn:sns:cn-north-1:123456789012:t',
        'arn:aws:sns:us-east-2:1234:t',
        'https://sns.us-east-2.amazonaws.com/',
      ]) {
        expect(SnsTopic.parse(bad), isNull, reason: bad);
      }
    });
  });

  group('SnsMessage.parse', () {
    test('needs every signed field', () {
      final good = signedSnsMessage();
      expect(SnsMessage.parse(jsonEncode(good)), isNotNull);
      for (final key in good.keys.where((k) => k != 'Subject')) {
        expect(
          SnsMessage.parse(jsonEncode({...good}..remove(key))),
          isNull,
          reason: key,
        );
      }
      expect(SnsMessage.parse('not json'), isNull);
      expect(SnsMessage.parse('[]'), isNull);
      expect(SnsMessage.parse(jsonEncode({...good, 'Type': 'Other'})), isNull);
    });

    test('a confirmation needs its token and address', () {
      final good = signedSnsMessage(type: 'SubscriptionConfirmation');
      expect(SnsMessage.parse(jsonEncode(good)), isNotNull);
      expect(
        SnsMessage.parse(jsonEncode({...good}..remove('SubscribeURL'))),
        isNull,
      );
    });
  });

  group('SnsVerifier', () {
    test('accepts a genuine message with either signature version', () async {
      for (final version in ['1', '2']) {
        final message = parse(
          signedSnsMessage(signatureVersion: version, subject: 'Hello'),
        );
        expect(await verifier.verify(message), isTrue, reason: version);
      }
    });

    test('accepts a confirmation message', () async {
      expect(
        await verifier.verify(
          parse(signedSnsMessage(type: 'SubscriptionConfirmation')),
        ),
        isTrue,
      );
    });

    test('fetches the certificate once and reuses it', () async {
      await verifier.verify(parse(signedSnsMessage()));
      await verifier.verify(parse(signedSnsMessage(messageId: 'another')));
      expect(fetched, [Uri.parse(testCertUrl)]);
    });

    test('refuses a changed message', () async {
      final fields = signedSnsMessage(message: '{"a":1}');
      for (final change in [
        {'Message': '{"a":2}'},
        {'MessageId': 'other'},
        {'Timestamp': '2026-11-26T21:00:00.000Z'},
        {'Subject': 'added'},
      ]) {
        expect(
          await verifier.verify(parse({...fields, ...change})),
          isFalse,
          reason: '$change',
        );
      }
    });

    test('refuses a signature from another version or garbage', () async {
      final fields = signedSnsMessage();
      expect(
        await verifier.verify(parse({...fields, 'SignatureVersion': '1'})),
        isFalse,
      );
      expect(
        await verifier.verify(parse({...fields, 'SignatureVersion': '3'})),
        isFalse,
      );
      expect(
        await verifier.verify(parse({...fields, 'Signature': '!!not base64'})),
        isFalse,
      );
      expect(
        await verifier.verify(parse({...fields, 'Signature': 'AAAA'})),
        isFalse,
      );
    });

    test('refuses a validly signed message from another topic', () async {
      final other = signedSnsMessage(
        topicArn: 'arn:aws:sns:us-east-2:999999999999:attacker',
      );
      expect(await verifier.verify(parse(other)), isFalse);
      expect(fetched, isEmpty);
    });

    test('never fetches a certificate from another address', () async {
      for (final url in [
        'http://sns.us-east-2.amazonaws.com/cert.pem',
        'https://sns.us-west-2.amazonaws.com/cert.pem',
        'https://evil.example/cert.pem',
        'https://sns.us-east-2.amazonaws.com.evil.example/cert.pem',
        'https://user@sns.us-east-2.amazonaws.com/cert.pem',
        'https://sns.us-east-2.amazonaws.com:8443/cert.pem',
        'https://sns.us-east-2.amazonaws.com/cert.txt',
        'not a url',
      ]) {
        expect(
          await verifier.verify(parse(signedSnsMessage(certUrl: url))),
          isFalse,
          reason: url,
        );
      }
      expect(fetched, isEmpty);
    });

    test('refuses when the certificate cannot be fetched or read', () async {
      certificateStatus = 500;
      expect(await verifier.verify(parse(signedSnsMessage())), isFalse);

      final unreadable = SnsVerifier(
        topic: SnsTopic.parse(testTopicArn)!,
        client: MockClient((_) async => http.Response('garbage', 200)),
      );
      expect(await unreadable.verify(parse(signedSnsMessage())), isFalse);

      final failing = SnsVerifier(
        topic: SnsTopic.parse(testTopicArn)!,
        client: MockClient((_) async => throw http.ClientException('down')),
      );
      expect(await failing.verify(parse(signedSnsMessage())), isFalse);
    });

    test('refuses an oversized certificate', () async {
      final small = SnsVerifier(
        topic: SnsTopic.parse(testTopicArn)!,
        client: client,
        maxCertificateBytes: 100,
      );
      expect(await small.verify(parse(signedSnsMessage())), isFalse);
    });
  });
}
