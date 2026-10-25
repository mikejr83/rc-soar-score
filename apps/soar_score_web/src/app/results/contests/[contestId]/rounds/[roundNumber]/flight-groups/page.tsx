import type { Metadata } from "next";

import { ContestView } from "@/components/results/contest-view";
import { parseRound } from "@/lib/results/round-param";

export const metadata: Metadata = { title: "Flight group scores" };

/** The flight groups of a round; `?pilot=` scrolls to that pilot's flight. */
export default async function FlightGroupsPage({
  params,
  searchParams,
}: {
  params: Promise<{ roundNumber: string }>;
  searchParams: Promise<{ pilot?: string | string[] }>;
}) {
  const [{ roundNumber }, { pilot }] = await Promise.all([params, searchParams]);
  return (
    <ContestView
      view="flightGroups"
      round={parseRound(roundNumber)}
      pilotKey={Array.isArray(pilot) ? pilot[0] : pilot}
    />
  );
}
