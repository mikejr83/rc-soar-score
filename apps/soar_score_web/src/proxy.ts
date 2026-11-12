import { NextResponse, type NextRequest } from 'next/server';

import { apiRequestHeaders, apiTarget } from '@/lib/api-proxy';

/**
 * Same-origin proxy to the API server (Fly.io): `/api/*` goes to
 * `SOAR_SCORE_API_URL` (set in Vercel for production; docs/deploying.md).
 *
 * It does what a `rewrites()` entry would, and adds the visitor's address and
 * the shared secret (`TRUSTED_PROXY_SECRET`) so the API's rate limits count
 * visitors, not this server (#904).
 */
export function proxy(request: NextRequest) {
  const target = apiTarget(
    request.nextUrl.pathname,
    request.nextUrl.search,
    process.env.SOAR_SCORE_API_URL,
  );
  return NextResponse.rewrite(new URL(target), {
    request: {
      headers: apiRequestHeaders(
        request.headers,
        process.env.TRUSTED_PROXY_SECRET,
      ),
    },
  });
}

export const config = { matcher: '/api/:path*' };
