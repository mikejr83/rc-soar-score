import type { Metadata } from "next";

import { LegalPage } from "@/components/legal-page";
import { pageMetadata } from "@/lib/page-metadata";

export const metadata: Metadata = pageMetadata("Terms of Service");

/** Terms of service (`/terms`). Source: src/content/legal/terms.md (#219). */
export default function TermsPage() {
  return <LegalPage name="terms" />;
}
