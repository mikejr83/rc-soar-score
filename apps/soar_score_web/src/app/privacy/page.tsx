import type { Metadata } from "next";

import { LegalPage } from "@/components/legal-page";

export const metadata: Metadata = { title: "Privacy Policy" };

/** Privacy policy (`/privacy`). Source: src/content/legal/privacy.md (#219). */
export default function PrivacyPage() {
  return <LegalPage name="privacy" />;
}
