import { ContestView } from "@/components/results/contest-view";
import { parseRound } from "@/lib/results/round-param";

/** Overall Individual Results as of a round. */
export default async function ContestRoundPage({
  params,
}: {
  params: Promise<{ roundNumber: string }>;
}) {
  const { roundNumber } = await params;
  return <ContestView view="overall" round={parseRound(roundNumber)} />;
}
