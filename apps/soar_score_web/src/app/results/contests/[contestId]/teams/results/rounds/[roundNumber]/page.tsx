import type { Metadata } from "next";

import { ContestView } from "@/components/results/contest-view";
import { parseRound } from "@/lib/results/round-param";

export const metadata: Metadata = { title: "Team scores" };

/** Team Scores as of a round. */
export default async function TeamResultsRoundPage({
  params,
}: {
  params: Promise<{ roundNumber: string }>;
}) {
  const { roundNumber } = await params;
  return <ContestView view="teams" round={parseRound(roundNumber)} />;
}
