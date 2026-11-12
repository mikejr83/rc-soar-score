import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:test/test.dart';

void main() {
  Request request(Map<String, String> headers) =>
      Request('POST', Uri.parse('http://localhost/x'), headers: headers);
  const secret = 'proxy-secret-proxy-secret-proxy-secret';

  test('direct requests use the address Fly saw', () {
    expect(
      clientAddressOf(request({'fly-client-ip': '203.0.113.7'})),
      '203.0.113.7',
    );
    expect(clientAddressOf(request({})), 'unknown');
    expect(clientAddressOf(request({'fly-client-ip': 'junk'})), 'unknown');
  });

  test('a forwarded address is believed only with the proxy secret', () {
    final headers = {
      'fly-client-ip': '76.76.21.21',
      forwardedClientHeader: '203.0.113.7',
    };
    for (final given in <String?>[null, 'wrong', '']) {
      expect(
        clientAddressOf(
          request({...headers, proxySecretHeader: ?given}),
          trustedProxySecret: secret,
        ),
        '76.76.21.21',
        reason: 'secret "$given"',
      );
    }
    expect(
      clientAddressOf(
        request({...headers, proxySecretHeader: secret}),
        trustedProxySecret: secret,
      ),
      '203.0.113.7',
    );
    // No secret configured: the headers mean nothing, even if a caller sends
    // some.
    expect(
      clientAddressOf(request({...headers, proxySecretHeader: secret})),
      '76.76.21.21',
    );
    expect(
      clientAddressOf(
        request({
          'fly-client-ip': '76.76.21.21',
          forwardedClientHeader: 'not an address',
          proxySecretHeader: secret,
        }),
        trustedProxySecret: secret,
      ),
      '76.76.21.21',
    );
  });

  group('normalizeAddress', () {
    test('keeps IPv4 and rejects what is not an address', () {
      expect(normalizeAddress(' 203.0.113.7 '), '203.0.113.7');
      expect(normalizeAddress('999.0.0.1'), isNull);
      expect(normalizeAddress('1.2.3'), isNull);
      expect(normalizeAddress(''), isNull);
      expect(normalizeAddress('a, b'), isNull);
    });

    test('unwraps IPv4-mapped IPv6 and brackets', () {
      expect(normalizeAddress('::ffff:203.0.113.7'), '203.0.113.7');
      expect(normalizeAddress('[2001:db8::1]'), '2001:db8:0:0::/64');
    });

    test('reduces IPv6 to the /64, whatever the spelling', () {
      const same = '2001:db8:aaaa:1::/64';
      expect(normalizeAddress('2001:db8:aaaa:1::5'), same);
      expect(normalizeAddress('2001:0DB8:aaaa:0001:ffff:0:0:9'), same);
      expect(normalizeAddress('2001:db8:aaaa:1:2:3:4:5%eth0'), same);
      expect(normalizeAddress('2001:db8:aaaa:2::5'), isNot(same));
      expect(normalizeAddress('::1'), '0:0:0:0::/64');
    });

    test('rejects malformed IPv6', () {
      expect(normalizeAddress('2001:db8::1::2'), isNull);
      expect(normalizeAddress('2001:db8:1:2:3:4:5'), isNull);
      expect(normalizeAddress('2001:db8:1:2:3:4:5:6:7'), isNull);
      expect(normalizeAddress('2001:zz8::1'), isNull);
      expect(normalizeAddress('12345::1'), isNull);
    });
  });
}
