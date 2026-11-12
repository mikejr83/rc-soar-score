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
  // `/api/*` is proxied to the API server by src/proxy.ts.
};

export default nextConfig;
