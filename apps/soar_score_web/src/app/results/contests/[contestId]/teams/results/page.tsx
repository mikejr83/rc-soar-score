import type { Metadata } from "next";

import { ContestView } from "@/components/results/contest-view";
import { pageMetadata } from "@/lib/page-metadata";

export const metadata: Metadata = pageMetadata("Team scores");

/** Team Scores as of the latest round with scores. */
export default function TeamResultsPage() {
  return <ContestView view="teams" />;
}
