import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // The Flutter site's two redirect-only routes (router.dart, docs_routes.dart).
  async redirects() {
    return [
      { source: "/results", destination: "/results/contests", permanent: false },
      { source: "/help", destination: "/docs", permanent: false },
    ];
  },
};

export default nextConfig;
