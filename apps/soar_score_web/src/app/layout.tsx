import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";

import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { siteName, tagline } from "@/lib/site";

import { accent, body, display } from "./fonts";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: `${siteName} · ${tagline}`,
    template: `%s · ${siteName}`,
  },
  description:
    "Scoring and management for RC sailplane soaring contests: run a contest, enter and check scores, and publish results for pilots and spectators.",
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
    <html lang="en" className={`${display.variable} ${body.variable} ${accent.variable}`}>
      <body style={{ minHeight: "100dvh", display: "flex", flexDirection: "column" }}>
        <SiteHeader />
        <main id="main" style={{ flex: 1 }}>
          {children}
        </main>
        <SiteFooter />
      </body>
    </html>
  );
}
