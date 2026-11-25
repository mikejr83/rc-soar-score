import type { NextConfig } from 'next';

// #683: security headers on every route. CSP starts as Report-Only so the
// first deployment can prove normal flows are clean before enforcing.
const isDev = process.env.NODE_ENV === 'development';

// External hosts this site actually loads (grep of src/):
// - challenges.cloudflare.com: Cloudflare Turnstile script and its challenge
//   iframe (support form, when NEXT_PUBLIC_TURNSTILE_SITE_KEY is set).
// - va.vercel-scripts.com: the Web Analytics debug script, dev only;
//   production injects /_vercel/insights/script.js and posts events to
//   /_vercel/insights/event on this origin, so it needs no external host.
// Nothing else: the three brand fonts are local (app/fonts.ts), and the
// github.com / gnu.org / creativecommons.org / app, score and api hosts in
// the source are navigation links or the server-side proxy target, never
// subresources, so they need no CSP entries.
// 'unsafe-inline' stays in script-src because layout.tsx carries an inline
// theme script and Next injects its own inline scripts; enforcing (instead
// of report-only) should move to per-request nonces via the proxy.
const cspReportOnly = [
  "default-src 'self'",
  `script-src 'self' 'unsafe-inline' https://challenges.cloudflare.com${
    isDev ? " 'unsafe-eval' https://va.vercel-scripts.com" : ''
  }`,
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data:",
  "connect-src 'self' https://challenges.cloudflare.com",
  "font-src 'self'",
  "frame-src 'self' https://challenges.cloudflare.com",
  "child-src https://challenges.cloudflare.com",
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "frame-ancestors 'none'",
].join('; ');

const nextConfig: NextConfig = {
  // The Flutter site's two redirect-only routes (router.dart, docs_routes.dart).
  async redirects() {
    return [
      // One indexed host: www goes to the apex (#679).
      {
        source: '/:path*',
        has: [{ type: 'host', value: 'www.rcsoarscore.com' }],
        destination: 'https://rcsoarscore.com/:path*',
        permanent: true,
      },
      {
        source: '/results',
        destination: '/results/contests',
        permanent: false,
      },
      { source: '/help', destination: '/docs', permanent: false },
    ];
  },
  // Security headers for every route (#683). X-Frame-Options is the legacy
  // twin of frame-ancestors 'none' in the policy above.
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
          { key: 'X-Frame-Options', value: 'DENY' },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()',
          },
          { key: 'Content-Security-Policy-Report-Only', value: cspReportOnly },
        ],
      },
    ];
  },
  // `/api/*` is proxied to the API server by src/proxy.ts.
};

export default nextConfig;
