import type { Metadata } from "next";

import { LegalPage } from "@/components/legal-page";

export const metadata: Metadata = { title: "Terms of Service" };

/** Terms of service (`/terms`). Source: src/content/legal/terms.md (#219). */
export default function TermsPage() {
  return <LegalPage name="terms" />;
}
