import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";

import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { siteName, siteUrl, tagline } from "@/lib/site";

import { accent, body, display } from "./fonts";
import "./globals.css";
import { Analytics } from "@vercel/analytics/next";

const description =
  "Scoring and management for RC sailplane soaring contests: run a contest, enter and check scores, and publish results for pilots and spectators.";
const shareImage = {
  url: "/brand/share-image.png",
  width: 1200,
  height: 630,
  alt: `${siteName}: ${tagline}`,
};

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  // Relative to each page, so every route names itself as its canonical URL.
  alternates: { canonical: "./" },
  openGraph: {
    type: "website",
    siteName,
    title: `${siteName} · ${tagline}`,
    description,
    images: [shareImage],
  },
  twitter: {
    card: "summary_large_image",
    title: `${siteName} · ${tagline}`,
    description,
    images: [shareImage.url],
  },
  title: {
    default: `${siteName} · ${tagline}`,
    template: `%s · ${siteName}`,
  },
  description,
  icons: {
    icon: "/brand/rc-soar-score-mark-tiny.svg",
    apple: "/brand/rc-soar-score-app-icon.svg",
  },
};

export const viewport: Viewport = {
  themeColor: "#1c1b1a",
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" className={`no-js ${display.variable} ${body.variable} ${accent.variable}`} suppressHydrationWarning>
      <body style={{ minHeight: "100dvh", display: "flex", flexDirection: "column" }}>
        {/* Scroll reveals hide content until JavaScript runs; without it, globals.css shows everything.
            The stored theme choice is applied here too, before first paint. */}
        <script
          dangerouslySetInnerHTML={{
            __html:
              "document.documentElement.classList.remove('no-js');try{var t=localStorage.getItem('theme');if(t)document.documentElement.dataset.theme=t}catch(e){}",
          }}
        />
        <SiteHeader />
        <main id="main" style={{ flex: 1 }}>
          {children}
        </main>
        <SiteFooter />
        <Analytics />
      </body>
    </html>
  );
}
