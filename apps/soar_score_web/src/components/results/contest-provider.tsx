"use client";

import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from "react";

import { loadContest, type ContestLoadResult } from "@/lib/results/contest-load";

interface ContestContextValue {
  contestId: string;
  /** Undefined while loading. */
  result?: ContestLoadResult;
  reload: () => void;
}

const ContestContext = createContext<ContestContextValue | null>(null);

/**
 * Loads a published contest once per id and shares the outcome with every
 * view and round route beneath it, so moving between them keeps the loaded
 * contest (the Flutter site's shared page key).
 */
export function ContestProvider({ contestId, children }: { contestId: string; children: ReactNode }) {
  const [generation, setGeneration] = useState(0);
  // Keyed by what was asked for, so a new id or a reload reads as "loading"
  // without a reset inside the effect.
  const key = `${contestId}#${generation}`;
  const [loaded, setLoaded] = useState<{ key: string; result: ContestLoadResult }>();
  const result = loaded?.key === key ? loaded.result : undefined;

  useEffect(() => {
    const controller = new AbortController();
    loadContest(contestId, controller.signal).then((r) => {
      if (!controller.signal.aborted) setLoaded({ key, result: r });
    });
    return () => controller.abort();
  }, [contestId, key]);

  const reload = useCallback(() => setGeneration((g) => g + 1), []);

  return <ContestContext.Provider value={{ contestId, result, reload }}>{children}</ContestContext.Provider>;
}

export function useContest(): ContestContextValue {
  const value = useContext(ContestContext);
  if (!value) throw new Error("useContest outside ContestProvider");
  return value;
}
