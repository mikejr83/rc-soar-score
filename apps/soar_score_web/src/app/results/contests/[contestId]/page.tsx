import type { Metadata } from "next";

import { ContestView } from "@/components/results/contest-view";
import { pageMetadata } from "@/lib/page-metadata";

// The contest name is only known in the browser (the page reads the API client-side), so previews use a generic title.
export const metadata: Metadata = pageMetadata("Contest results", "Standings, flight groups and team scores for a published RC soaring contest.");

/** Overall Individual Results as of the latest round with scores. */
export default function ContestPage() {
  return <ContestView view="overall" />;
}
