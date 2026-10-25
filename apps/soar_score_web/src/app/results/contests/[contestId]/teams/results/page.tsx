import type { Metadata } from "next";

import { ContestView } from "@/components/results/contest-view";

export const metadata: Metadata = { title: "Team scores" };

/** Team Scores as of the latest round with scores. */
export default function TeamResultsPage() {
  return <ContestView view="teams" />;
}
