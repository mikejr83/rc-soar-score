import 'package:shelf/shelf.dart';

/// Header the web site's proxy sets with the visitor's address (Vercel knows
/// it; Fly sees only Vercel). Believed only with [proxySecretHeader].
const forwardedClientHeader = 'x-soar-client-ip';

/// Header the web site's proxy sets with the shared secret that proves it
/// set [forwardedClientHeader] (`TRUSTED_PROXY_SECRET` on the server).
const proxySecretHeader = 'x-soar-proxy-secret';

/// The address of the caller of [request], normalized, or `unknown`.
///
/// Fly's proxy sets `Fly-Client-IP` from the connection it accepted and
/// replaces anything a client sent, so it is the caller itself on a direct
/// request, and the web proxy's address on a request that came through the
/// site's `/api` proxy. For the second case the proxy adds
/// [forwardedClientHeader] and [proxySecretHeader]; the forwarded address is
/// used only when the secret matches [trustedProxySecret], never otherwise,
/// so a direct caller cannot choose its own address. With no secret
/// configured, only the Fly address counts.
///
/// IPv6 addresses collapse to their /64, which is what one subscriber
/// receives, so rotating the low bits does not dodge a limit.
String clientAddressOf(Request request, {String? trustedProxySecret}) {
  final secret = trustedProxySecret;
  if (secret != null && secret.isNotEmpty) {
    final given = request.headers[proxySecretHeader];
    if (given != null && _sameText(given, secret)) {
      final forwarded = normalizeAddress(
        request.headers[forwardedClientHeader] ?? '',
      );
      if (forwarded != null) return forwarded;
    }
  }
  return normalizeAddress(request.headers['fly-client-ip'] ?? '') ?? 'unknown';
}

bool _sameText(String a, String b) {
  // Compares every character, so the time does not tell how much matched.
  var diff = a.length ^ b.length;
  for (var i = 0; i < a.length && i < b.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

final _ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');

/// [raw] as an IPv4 address, or an IPv6 /64 (`2001:db8:0:1::/64`); null when
/// it is neither.
String? normalizeAddress(String raw) {
  var text = raw.trim().toLowerCase();
  if (text.startsWith('[') && text.endsWith(']')) {
    text = text.substring(1, text.length - 1);
  }
  final zone = text.indexOf('%');
  if (zone >= 0) text = text.substring(0, zone);
  if (text.startsWith('::ffff:') && _ipv4.hasMatch(text.substring(7))) {
    text = text.substring(7);
  }
  final v4 = _ipv4.firstMatch(text);
  if (v4 != null) {
    final parts = [for (var i = 1; i <= 4; i++) int.parse(v4.group(i)!)];
    return parts.any((p) => p > 255) ? null : parts.join('.');
  }
  if (!text.contains(':') || text.length > 45) return null;
  final halves = text.split('::');
  if (halves.length > 2) return null;
  List<String> groups(String s) => s.isEmpty ? [] : s.split(':');
  final head = groups(halves[0]);
  final tail = halves.length == 2 ? groups(halves[1]) : <String>[];
  if (halves.length == 1 && head.length != 8) return null;
  if (halves.length == 2 && head.length + tail.length > 7) return null;
  final all = [
    ...head,
    if (halves.length == 2) ...List.filled(8 - head.length - tail.length, '0'),
    ...tail,
  ];
  final hex = RegExp(r'^[0-9a-f]{1,4}$');
  if (all.length != 8 || !all.every(hex.hasMatch)) return null;
  return '${all.take(4).map((g) => int.parse(g, radix: 16).toRadixString(16)).join(':')}::/64';
}
