import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto_keys/crypto_keys.dart' show RsaPrivateKey;
import 'package:pointycastle/export.dart' as pc;
import 'package:soar_score_server/mail/ses_feedback/sns_message.dart';
import 'package:x509/x509.dart' as x509;

/// A throwaway RSA key and self-signed certificate made only for these tests
/// (`openssl req -x509`, CN sns.us-east-2.amazonaws.com). They protect
/// nothing and are never used outside the test suite.
const testSigningKeyPem = '''
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAsX0aOlGIQN6mZeIFFlHhvnLBla+diflTFylaFMLKwHRLAyc9
FvVA2BciKbW4Xe5KozSkYnt0WWSW15JHxwgywsI4wgZ0mg5YQbmpuXJL0oYD3qGB
2kECV6X1TvLX8aSFOW1jyNUHSSEIDP8CWD6Xm3cV8E4jwNiP0tPUA0jYMwwWMDWa
GnHdOWlRSv2ZO7MyRX8z+BBtPec9zP1JlVZAciAONbzmpQf3t+vNHfI0z6aRynKQ
LXuUualj4esXeGmHqI/8JhPUZPP9MdHrucGA2iQDtlB3zIKskvuguzLuYnbOJ728
/DnqExIeBs4gnjMx/fqmAaa0lPuetCwu2dH3kwIDAQABAoIBAAVMvmWYBLv+1kzW
+kr8ogN3qcFfta+hokNgBQkyR9ateuiL9xg/yUr5UivUDZci5mtWs2CpwEhDrFrv
1H6zGwv/lF6ZQ/quRqqIXkGo4Kl+yC2RWy9ERpnwBIgZbmgQJn3wfuBvGYsOFl45
SPijb61UvBCCHWy641V0lmxlJV5NGxWL7NnPbjTGsMrZUkQWHGR0U/mdcK5BwXc2
mW6f/rn+znYqAZ72oCdKSQlgVSqDAYCHHMxxdgFLInbPLX/pRAvka1w6LQVQJd+f
p8wJPZBy1uCxi6C4+qaqa8YzZZxCiWv93I6IKhchy9/us3wB+i1/FPFUT7XtkjOv
Y5o0jAECgYEA9RKrqR/POypBQxluO4t/mh2I6dHP454PFzMUvPLKXQMGT51tK0fx
yd7G69D1A15gSC4zeBbW/2MgkMI3Q+Fv9Aq5S/QId+jSrmSyFn30YKOq3BncLsYP
ScLktUMas/x7L2QX6xjSZV8ALz3sPo+2F0xtzl8Qo9HQl6mlwzjyb6MCgYEAuWcB
vQdbtSbT7Pxkl/1a0TghJEKQqPCDA8cP6VXNHtORtwV+NdfSWZeyrxIfhGQhS2b0
F8jIVBeXyizZ54NAi7JOVU2oQnf+CHitg4Xjsuj596bx3k2oKEDGQiuQZ10wVLuc
VErL/EMZRIkwfXnPNp3SuNRA6wkUES5h4nvnF1ECgYEAz3cWyv2auUN0LBGDN/VH
+He4R/jOPKq5q7IahDolBchht1RV7qXhEjv9ufQS9t8WMwSpnaf4KgsIroM7tcNK
uxW494uG/7uhXvDvsgq+rnDfW6SouRACMTdD1g8Qs/2xatUZSnSg6CAcT+Hj9LJE
PET/UA06UPR12W5MXY//7HECgYA4kuQG6F3lkymL4SBY+Khjuzrxs5Ys1udDmdST
IOlshKasMHLovyiiyhVuMpuHbH50YcAOGeh3MJPSz4jWikiB2DDq+r1jOvY7Y4ee
4JYwm8La/QhFC3FKhyl4O47e26LJ2E3FsuU33smxDiPLxgWi5tnMKIh+r9B9xad8
0s4bYQKBgQDZ9dXdpWpRe4Dn1zV8qgcy2uoCJW88Ku6yu3D8Bbjncgw3PVFrEqYR
r+GtURoU3cVxAzEa65c1OE5KFRo0EjUiuwIE21VfsceP4L4ziaFWHnY/SnxW4Q3k
j03UGElKno4yN63qtwBVv9V1t+6u/u7F/OlKsaRiZsZ7y6C1NTZqYg==
-----END RSA PRIVATE KEY-----
''';

const testSigningCertPem = '''
-----BEGIN CERTIFICATE-----
MIIDLzCCAhegAwIBAgIUVWqbgky57YFv5iRGmFVdJ//MdpQwDQYJKoZIhvcNAQEL
BQAwJjEkMCIGA1UEAwwbc25zLnVzLWVhc3QtMi5hbWF6b25hd3MuY29tMCAXDTI2
MTEyNjIwMDEzNVoYDzIxMjYxMTAyMjAwMTM1WjAmMSQwIgYDVQQDDBtzbnMudXMt
ZWFzdC0yLmFtYXpvbmF3cy5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQCxfRo6UYhA3qZl4gUWUeG+csGVr52J+VMXKVoUwsrAdEsDJz0W9UDYFyIp
tbhd7kqjNKRie3RZZJbXkkfHCDLCwjjCBnSaDlhBuam5ckvShgPeoYHaQQJXpfVO
8tfxpIU5bWPI1QdJIQgM/wJYPpebdxXwTiPA2I/S09QDSNgzDBYwNZoacd05aVFK
/Zk7szJFfzP4EG095z3M/UmVVkByIA41vOalB/e3680d8jTPppHKcpAte5S5qWPh
6xd4aYeoj/wmE9Rk8/0x0eu5wYDaJAO2UHfMgqyS+6C7Mu5ids4nvbz8OeoTEh4G
ziCeMzH9+qYBprSU+560LC7Z0feTAgMBAAGjUzBRMB0GA1UdDgQWBBTR5VwT4nTq
aqWHte2tBeZgoDdsWzAfBgNVHSMEGDAWgBTR5VwT4nTqaqWHte2tBeZgoDdsWzAP
BgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQCo7K5IMN0c/M3DSSom
iqKN1IDUmCCEtMlDiT8CLbAvvo3qgDdzVO3pskYBoJtAuYRJIc51+ICAzxxBGKI7
xcRJiHtzkB3vHOcpzkK9vCqeIXESPhvRjabLA2FoZYYEOBZdlxLmXyr3rIZxCPtC
JSN+8WIdQ5Nosa4CtIopomlyT8L1ds2xf6X6ynC7SRiR9bcvxuQiCI3pIb9uOguO
/qphPQag+8cNFQDyZKH8+5RHxlnzCRk5py8lOp6VWk81GB8FhvlHTwKvH0zel7yk
bL7gqytRS++YycR0ZpslrzL/hRXpPERPNxFmBpTBojzs+c06VN/89/Vhd5pDpLQH
JwIT
-----END CERTIFICATE-----
''';

const testTopicArn =
    'arn:aws:sns:us-east-2:123456789012:rcsoarscore-ses-feedback';
const testCertUrl =
    'https://sns.us-east-2.amazonaws.com/SimpleNotificationService-test.pem';
const testSubscribeUrl =
    'https://sns.us-east-2.amazonaws.com/?Action=ConfirmSubscription&Token=t';

/// An SNS message as the service posts it, signed with the test key.
Map<String, Object?> signedSnsMessage({
  String type = 'Notification',
  String message = '{}',
  String? subject,
  String topicArn = testTopicArn,
  String certUrl = testCertUrl,
  String signatureVersion = '2',
  String messageId = '22b80b92-fdea-4c2c-8f9d-bdfb0c7bf324',
  String? subscribeUrl,
}) {
  final fields = <String, Object?>{
    'Type': type,
    'MessageId': messageId,
    'TopicArn': topicArn,
    'Message': message,
    'Timestamp': '2026-11-26T20:00:00.000Z',
    'SignatureVersion': signatureVersion,
    'SigningCertURL': certUrl,
    'Subject': ?subject,
    if (type != 'Notification') ...{
      'SubscribeURL': subscribeUrl ?? testSubscribeUrl,
      'Token': 'token-1',
    },
  };
  final parsed = SnsMessage.parse(jsonEncode({...fields, 'Signature': 'x'}))!;
  fields['Signature'] = sign(parsed.stringToSign, signatureVersion);
  return fields;
}

/// The base64 RSA signature of [text] under the test key.
String sign(String text, String signatureVersion) {
  final pair = x509.parsePem(testSigningKeyPem).single as dynamic;
  final key = pair.privateKey as RsaPrivateKey;
  final signer = signatureVersion == '1'
      ? pc.RSASigner(pc.SHA1Digest(), '06052b0e03021a')
      : pc.RSASigner(pc.SHA256Digest(), '0609608648016503040201');
  signer.init(
    true,
    pc.PrivateKeyParameter<pc.RSAPrivateKey>(
      pc.RSAPrivateKey(
        key.modulus,
        key.privateExponent,
        key.firstPrimeFactor,
        key.secondPrimeFactor,
      ),
    ),
  );
  return base64.encode(
    signer.generateSignature(Uint8List.fromList(utf8.encode(text))).bytes,
  );
}

/// An SES bounce or complaint notification for [messageId].
String sesNotification(
  String type,
  String messageId, {
  String bounceType = 'Permanent',
  String field = 'notificationType',
}) => jsonEncode({
  field: type,
  if (type == 'Bounce')
    'bounce': {
      'bounceType': bounceType,
      'bounceSubType': 'General',
      'bouncedRecipients': [
        {'emailAddress': 'alex.rivera@example.com', 'diagnosticCode': 'smtp'},
      ],
    },
  if (type == 'Complaint')
    'complaint': {
      'complainedRecipients': [
        {'emailAddress': 'alex.rivera@example.com'},
      ],
    },
  'mail': {
    'messageId': messageId,
    'destination': ['alex.rivera@example.com'],
  },
});
