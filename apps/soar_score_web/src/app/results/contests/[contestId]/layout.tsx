import type { Metadata } from "next";
import type { ReactNode } from "react";

import { ContestProvider } from "@/components/results/contest-provider";

export const metadata: Metadata = { title: "Contest results" };

/** Every view and round of one contest shares the loaded publication. */
export default async function ContestLayout({
  params,
  children,
}: {
  params: Promise<{ contestId: string }>;
  children: ReactNode;
}) {
  const { contestId } = await params;
  return <ContestProvider contestId={contestId}>{children}</ContestProvider>;
}
