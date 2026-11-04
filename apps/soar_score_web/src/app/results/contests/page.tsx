import type { Metadata } from "next";
import { Suspense } from "react";

import { ContestSearch } from "@/components/results/contest-search";
import { Skeleton } from "@/components/results/skeleton";
import { pageMetadata } from "@/lib/page-metadata";

export const metadata: Metadata = pageMetadata("Contests", "Find a published RC soaring contest and follow its results as they come in.");

export default function ContestsPage() {
  return (
    <Suspense
      fallback={
        <div className="wrap section--tight">
          <Skeleton rows={6} />
        </div>
      }
    >
      <ContestSearch />
    </Suspense>
  );
}
