import type { NextConfig } from 'next';

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
  // Same-origin proxy to the API server (Fly.io). SOAR_SCORE_API_URL is set
  // in Vercel for production; see docs/deploying.md.
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${process.env.SOAR_SCORE_API_URL ?? 'http://localhost:8080'}/:path*`,
      },
    ];
  },
};

export default nextConfig;
