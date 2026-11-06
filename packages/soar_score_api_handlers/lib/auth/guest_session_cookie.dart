/// The guest session cookie of the self-scoring web app.
///
/// The browser keeps the session where scripts cannot read it: `HttpOnly`,
/// `Secure`, `SameSite=Lax`. The `__Host-` prefix makes browsers accept it
/// only with `Secure` and `Path=/` and no `Domain`, so it belongs to the API
/// host alone (`api.rcsoarscore.com`) and a sibling subdomain cannot set or
/// overwrite it. The self-scoring app on `score.rcsoarscore.com` is the same
/// site, so `Lax` cookies ride on its credentialed fetches.
const String guestSessionCookieName = '__Host-soar_guest';

/// The header a web client sends on every request, which a cross-site form
/// cannot add: it is what makes a cookie-authenticated write safe from
/// cross-site request forgery.
const String webClientHeader = 'x-requested-with';

/// The `Set-Cookie` value that stores [token] for [maxAge].
String guestSessionSetCookie(String token, Duration maxAge) =>
    '$guestSessionCookieName=$token; Max-Age=${maxAge.inSeconds}; Path=/; '
    'Secure; HttpOnly; SameSite=Lax';

/// The `Set-Cookie` value that removes the cookie.
String guestSessionClearCookie() =>
    '$guestSessionCookieName=; Max-Age=0; Path=/; Secure; HttpOnly; '
    'SameSite=Lax';

/// The session token in a `Cookie` header, or null.
String? guestSessionFromCookieHeader(String? header) {
  if (header == null) return null;
  for (final part in header.split(';')) {
    final pair = part.trim();
    final eq = pair.indexOf('=');
    if (eq > 0 && pair.substring(0, eq) == guestSessionCookieName) {
      final value = pair.substring(eq + 1);
      return value.isEmpty ? null : value;
    }
  }
  return null;
}
