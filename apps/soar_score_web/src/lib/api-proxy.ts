/** Header carrying the visitor's address to the API (`clientAddressOf`). */
export const forwardedClientHeader = 'x-soar-client-ip';

/** Header carrying the secret that proves the proxy set the address. */
export const proxySecretHeader = 'x-soar-proxy-secret';

/**
 * The visitor's address as the hosting platform saw it, or undefined.
 *
 * `x-vercel-forwarded-for` is set by Vercel and cannot be overridden by the
 * visitor; `x-real-ip` is Vercel's own too. Off Vercel (local dev) neither is
 * trustworthy, which is why the secret below is only set when one is found
 * and the API only believes the pair when the secret is configured.
 */
export function visitorAddress(headers: Headers): string | undefined {
  for (const name of ['x-vercel-forwarded-for', 'x-real-ip']) {
    const first = headers.get(name)?.split(',')[0]?.trim();
    if (first) return first;
  }
  return undefined;
}

/**
 * The headers for the request the site forwards to the API server.
 *
 * Fly's proxy sees only this server's address on the forwarded request, so
 * the visitor's address travels in [forwardedClientHeader], with
 * [proxySecretHeader] (`TRUSTED_PROXY_SECRET`, the same value on Fly) to
 * prove it came from here. Whatever a visitor sent in those two headers is
 * dropped first. With no secret set, nothing is added and the API counts the
 * proxy's own address.
 */
export function apiRequestHeaders(
  incoming: Headers,
  secret: string | undefined,
): Headers {
  const headers = new Headers(incoming);
  headers.delete(forwardedClientHeader);
  headers.delete(proxySecretHeader);
  const address = secret ? visitorAddress(incoming) : undefined;
  if (secret && address) {
    headers.set(forwardedClientHeader, address);
    headers.set(proxySecretHeader, secret);
  }
  return headers;
}

/** Where `/api/<path>` goes: the API server, without the `/api` prefix. */
export function apiTarget(
  pathname: string,
  search: string,
  base: string = 'http://localhost:8080',
): string {
  return `${base.replace(/\/+$/, '')}${pathname.replace(/^\/api/, '')}${search}`;
}
