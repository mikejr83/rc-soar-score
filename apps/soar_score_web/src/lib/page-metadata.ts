import type { Metadata } from "next";

import { siteName, tagline } from "@/lib/site";

export const siteDescription =
  "Scoring and management for RC sailplane soaring contests: run a contest, enter and check scores, and publish results for pilots and spectators.";

export const shareImage = {
  url: "/brand/share-image.png",
  width: 1200,
  height: 630,
  alt: `${siteName}: ${tagline}`,
};

/**
 * Metadata for one page: its own title and description, repeated into the
 * Open Graph and Twitter tags. A page's `openGraph` replaces the root
 * layout's wholesale (Next does not merge it), so the site name, type and
 * share image are set here too (#680).
 */
export function pageMetadata(
  title: string,
  description: string = siteDescription,
): Metadata {
  const full = `${title} · ${siteName}`;
  return {
    title,
    description,
    openGraph: {
      type: "website",
      siteName,
      title: full,
      description,
      images: [shareImage],
    },
    twitter: {
      card: "summary_large_image",
      title: full,
      description,
      images: [shareImage.url],
    },
  };
}
